comm_target_env <- new.env()

.CommManager__register_target_callback <- function(comm, request) {
    target_callback <- comm_target_env[[request$content$target_name]]
    target_callback(comm, request)
}

CommManagerClass <- R6Class("CommManagerClass",
    public = list(
        initialize = function() {
            private$targets <- new.env()
            private$comms <- new.env()
        },

        register_comm_target = function(target_name, callback) {
            private$targets[[target_name]] <- callback
            invisible(hera_dot_call("CommManager__register_target", target_name, PACKAGE = "(embedding)"))
        },

        unregister_comm_target = function(target_name) {
            rm(list = target_name, private$targets)
            invisible(hera_dot_call("CommManager__unregister_target", target_name))
        },

        new_comm = function(target_name) {
            xp <- hera_dot_call("CommManager__new_comm", target_name)
            if (is.null(xp)) {
                stop(glue::glue("No target '{target_name}' registered"))
            }
            Comm$new(xp = xp)
        }
    ),

    private = list(
        targets = NULL,
        comms = NULL
    )
)
CommManager <- CommManagerClass$new()

Comm <- R6Class("Comm",
    public = list(
        initialize = function(xp) {
            private$xp <- xp
        },

        open = function(metadata = NULL, data = NULL) {
            js_metadata <- toJSON(metadata)
            js_data <- toJSON(data)

            invisible(hera_dot_call("Comm__open", private$xp, js_metadata, js_data))
        },

        close = function(metadata = NULL, data = NULL) {
            js_metadata <- toJSON(metadata)
            js_data <- toJSON(data)

            invisible(hera_dot_call("Comm__close", private$xp, js_metadata, js_data))
        },

        send = function(metadata = NULL, data = NULL) {
            js_metadata <- toJSON(metadata)
            js_data <- toJSON(data)

            invisible(hera_dot_call("Comm__send", private$xp, js_metadata, js_data))
        },

        on_close = function(handler) {
            private$close_handler <- handler
            invisible(hera_dot_call("Comm__on_close", private$xp, handler))
        },

        on_message = function(handler) {
            private$message_handler <- handler
            invisible(hera_dot_call("Comm__on_message", private$xp, handler))
        }
    ),

    active = list(
        id = function() {
            hera_dot_call("Comm__id", private$xp)
        },

        target_name = function() {
            hera_dot_call("Comm__target_name", private$xp)
        }
    ),

    private = list(
        xp = NULL,
        close_handler = NULL,
        message_handler = NULL
    )
)

Message <- R6Class("Message",
    public = list(
        initialize = function(xp) {
            private$xp <- xp
        },

        print = function() {
            print(cli::rule("$content"))
            str(self$content)

            print(cli::rule("$header"))
            str(self$header)

            print(cli::rule("$parent_header"))
            str(self$parent_header)

            print(cli::rule("$metadata"))
            str(self$metadata)
        }
    ),

    active = list(
        content = function() {
            fromJSON(hera_dot_call("Message__get_content", private$xp))
        },

        header = function() {
            fromJSON(hera_dot_call("Message__get_header", private$xp))
        },

        parent_header = function() {
            fromJSON(hera_dot_call("Message__get_parent_header", private$xp))
        },

        metadata = function() {
            fromJSON(hera_dot_call("Message__get_metadata", private$xp))
        }
    ),

    private = list(
        xp = NULL
    )
)
