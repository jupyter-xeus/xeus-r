Model <- R6::R6Class("jupyter.widget.Model", 
    public = list(
        comm = NULL, 

        initialize = function(layout, style, description = "model") {
            comm <- CommManager$new_comm("jupyter.widget", description)
            comm$on_message(function(request) {
                data <- request$content$data
                method <- data$method

                switch(
                    method, 
                    update = {
                        state <- data$state
                        private$state_ <- replace(private$states_, names(state), state)

                        if (!is.null(handler <- private$handlers[["update"]])) {
                            handler(state)
                        }

                        comm$send(
                            data = list(
                                method = "echo_update", state = state, buffer_paths = list()
                            )
                        )
                    }, 

                    custom = {
                        content <- data$content

                        if (!is.null(handler <- private$handlers[["custom"]])) {
                            handler(content)
                        }
                    }
                )

            })

            comm$on_close(function(request) {})

            private$state_$layout <- glue("IPY_MODEL_{layout$comm$id}")
            private$state_$style <- glue("IPY_MODEL_{style$comm$id}")

            comm$open(
                data = list(state = private$state_, buffer_paths = list()), 
                metadata = list(version = "2.1.0")
            )
            self$comm <- comm

            private$handlers <- new.env()
        }, 

        state = function(what) {
            if (missing(what)) {
                private$state_
            } else {
                private$state_[[what]]
            }
        }, 

        on_update = function(handler = NULL) {
            private$handlers[["update"]] <- handler
        }, 

        on_custom = function(handler = NULL) {
            private$handlers[["custom"]] <- handler
        },

        update = function(...) {
            state <- list(...)
            self$comm$send(
                data = list(method = "update", state = state, buffer_paths = list())
            )
        }
    ), 


    private = list(
        handlers = NULL
    )
    
)