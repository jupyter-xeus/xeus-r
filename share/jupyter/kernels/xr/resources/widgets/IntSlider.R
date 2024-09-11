IntSliderStyle <- R6::R6Class("jupyter.widget.IntSliderStyle", inherit = Style,
    public = list(
        initialize = function() {
            super$initialize("slider style")
        }
    ), 

    private = list(
        state_ = list(
            "_model_module" = "@jupyter-widgets/controls", 
            "_model_module_version" = "2.0.0", 
            "_model_name" = "SliderStyleModel", 
            "_view_count" = NULL, 
            "_view_module" = "@jupyter-widgets/base", 
            "_view_module_version" = "2.0.0", 
            "_view_name" = "StyleView", 
            "description_width" = "", 
            "handle_color" = NULL
        )
    )
)

IntSliderModel <- R6::R6Class("jupyter.widget.IntSliderModel", 
    public = list(
        comm = NULL, 

        initialize = function(layout, style) {
            comm <- CommManager$new_comm("jupyter.widget", "slider model")
            comm$on_message(function(request) {
                
                switch(
                    request$content$data$method, 
                    update = {
                        state <- request$content$data$state
                        private$state_ <- replace(private$states_, names(state), state)

                        if (!is.null(handler <- private$handlers[["update"]])) {
                            handler(request$content$data$state)
                        }

                        comm$send(
                            data = list(method = "echo_update", state = state, buffer_paths = list())
                        )
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
        }
    ), 

    private = list(
        handlers = NULL,

        state_ = list(
            "_dom_classes" = list(), 
            "_model_module" = "@jupyter-widgets/controls", 
            "_model_module_version" = "2.0.0", 
            "_model_name" = "IntSliderModel", 
            "_view_count" = NULL, 
            "_view_module" = "@jupyter-widgets/controls", 
            "_view_module_version" = "2.0.0", 
            "_view_name" = "IntSliderView", 
            "behavior" = "drag-tap", 
            "continuous_update" = TRUE, 
            "description" = "", 
            "description_allow_html" = FALSE, 
            "disabled" = FALSE, 
            "layout" = "IPY_MODEL_{layout$id}", 
            "max" = 100, 
            "min" = 0, 
            "orientation" = "horizontal", 
            "readout" = TRUE, 
            "readout_format" = "d", 
            "step" = 1, 
            "style" = "IPY_MODEL_{style$id}", 
            "tabbable" = NULL, 
            "tooltip" = NULL, 
            "value" = 0
        )
    )
)

IntSlider <- R6::R6Class("jupyter.widget.IntSlider", inherit = Widget,
    public = list(
        layout = NULL, 
        style = NULL, 
        model = NULL,

        initialize = function() {
            self$layout <- Layout$new()
            self$style  <- IntSliderStyle$new()
            self$model  <- IntSliderModel$new(self$layout, self$style)
        }, 

        mime_bundle = function() {
            data <- list(
                "text/plain" = unbox(
                    glue("<IntSlider id = {self$model$comm$id} value={self$model$state('value')})>")
                ), 
                "application/vnd.jupyter.widget-view+json" = list(
                    "version_major" = unbox(2L), 
                    "version_minor" = unbox(0L), 
                    "model_id" = unbox(self$model$comm$id)
                )
            )
            list(data = data, metadata = namedlist())
        }, 

        state = function(what) {
            self$model$state(what)
        }, 

        on_update = function(handler) {
            self$model$on_update(handler)
        }
    )
)
