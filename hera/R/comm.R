.CommManager__register_target_callback <- function(comm, request) {
    callback <- CommManager$target_callback(request$content$target_name)
    callback(comm, request)
}

CommManagerClass <- R6::R6Class("CommManagerClass",
    public = list(
        initialize = function() {
            private$env_targets <- new.env()
            private$env_comms <- new.env()
        },

        register_comm_target = function(target_name, callback = function(comm, message){}) {
            private$env_targets[[target_name]] <- callback
            invisible(hera_dot_call("CommManager__register_target", target_name))
        },

        unregister_comm_target = function(target_name) {
            rm(list = target_name, private$env_targets)
            invisible(hera_dot_call("CommManager__unregister_target", target_name))
        },

        new_comm = function(target_name, description = "") {
            hera_dot_call("CommManager__new_comm", target_name, description)
        },

        comms = function() {
            as.list(private$env_comms)
        },

        target_callback = function(target_name) {
            private$env_targets[[target_name]]
        },

        preserve = function(comm) {
            assign(comm$id, comm, envir = private$env_comms)
        },

        release = function(comm) {
            rm(list = comm$id, envir = private$env_comms)
        },

        get_comm_info = function(target_name = NULL) {
            hera_dot_call("CommManager__get_comm_info", target_name)
        }
    ),

    private = list(
        env_targets = NULL,
        env_comms = NULL
    )
)

# set later in zzz.R

#' Comm manager
#'
#' @export
CommManager <- NULL

Comm <- R6::R6Class("Comm",
    public = list(
        initialize = function(xp, description = "") {
            private$xp <- xp
            private$description <- description
            CommManager$preserve(self)
        },

        open = function(data = NULL, metadata = NULL) {
            js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
            js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

            invisible(hera_dot_call("Comm__open", private$xp, js_metadata, js_data))
        },

        close = function(data = NULL, metadata = NULL) {
            js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
            js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

            invisible(hera_dot_call("Comm__close", private$xp, js_metadata, js_data))
        },

        send = function(data = NULL, metadata = NULL) {
            js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
            js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

            invisible(hera_dot_call("Comm__send", private$xp, js_metadata, js_data))
        },

        on_close = function(handler) {
            private$close_handler <- function(request) {
                handler(request)
                self$finalize()
            }
            invisible(hera_dot_call("Comm__on_close", private$xp, private$close_handler))
        },

        on_message = function(handler) {
            private$message_handler <- handler
            invisible(hera_dot_call("Comm__on_message", private$xp, private$message_handler))
        },

        print = function() {
            writeLines(glue("<Comm id={self$id} target_name='{self$target_name}' description='{private$description}' >"))
        },

        finalize = function() {
            CommManager$release(self)
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
        description = "",
        close_handler = NULL,
        message_handler = NULL
    )
)

Message <- R6::R6Class("Message",
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
            jsonlite::fromJSON(hera_dot_call("Message__get_content", private$xp))
        },

        header = function() {
            jsonlite::fromJSON(hera_dot_call("Message__get_header", private$xp))
        },

        parent_header = function() {
            jsonlite::fromJSON(hera_dot_call("Message__get_parent_header", private$xp))
        },

        metadata = function() {
            jsonlite::fromJSON(hera_dot_call("Message__get_metadata", private$xp))
        }
    ),

    private = list(
        xp = NULL
    )
)
