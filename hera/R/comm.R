.CommManager__register_target_callback <- function(comm, request) {
    callback <- CommManager$target_callback(request$content$target_name)
    callback(comm, request)
}

#' Comm Manager class
#'
#' @rdname CommManager
CommManagerClass <- R6::R6Class("CommManagerClass",
  public = list(

    #' @param ... currently unused
    #' @param error_call see [rlang::args_error_context()]
    initialize = function(..., error_call = caller_env()) {
      rlang::check_dots_empty(call = error_call)

      private$env_targets <- new.env()
      private$env_comms <- new.env()
    },

    #' @param target_name name of the comm target, e.g. "jupyter.widgets"
    #' @param callback callback function taking two arguments 'comm' and 'message'.
    register_comm_target = function(target_name, callback = function(comm, message){}) {
        private$env_targets[[target_name]] <- callback
        invisible(hera_dot_call("CommManager__register_target", target_name))
    },

    #' @param target_name name of the comm target
    unregister_comm_target = function(target_name) {
        rm(list = target_name, private$env_targets)
        invisible(hera_dot_call("CommManager__unregister_target", target_name))
    },

    #' @param target_name name of the target
    #' @param description description of the comm
    new_comm = function(target_name, description = "") {
        hera_dot_call("CommManager__new_comm", target_name, description)
    },

    #' @return the list of currently open comms
    comms = function() {
        as.list(private$env_comms)
    },

    #' @param target_name name of the comm target
    #'
    #' @return the callback for that target name
    target_callback = function(target_name) {
        private$env_targets[[target_name]]
    },

    #' @param comm comm instance to preserve
    preserve = function(comm) {
        assign(comm$id, comm, envir = private$env_comms)
    },

    #' @param comm comm instance to release
    release = function(comm) {
        rm(list = comm$id, envir = private$env_comms)
    },

    #' @param target_name name of the target to get info about all comm opens. If NULL, info for comms for all targets are returned.
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
#' Instance of the [CommManagerClass] class.
#'
#' @export
CommManager <- NULL

#' Comm class
#'
#' @export
Comm <- R6::R6Class("Comm",
  public = list(

    #' @param xp external pointer to an instance of the C++ class `xeus::xcomm`
    #' @param description description of this comm
    initialize = function(xp, description = "") {
        private$xp <- xp
        private$description <- description
        CommManager$preserve(self)
    },

    #' @param data data
    #' @param metadata metadata
    open = function(data = NULL, metadata = NULL) {
        js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
        js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

        invisible(hera_dot_call("Comm__open", private$xp, js_metadata, js_data))
    },

    #' @param data data
    #' @param metadata metadata
    close = function(data = NULL, metadata = NULL) {
        js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
        js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

        invisible(hera_dot_call("Comm__close", private$xp, js_metadata, js_data))
    },

    #' @param data data
    #' @param metadata metadata
    send = function(data = NULL, metadata = NULL) {
        js_metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE, null = if (is.null(metadata)) "list" else "null")
        js_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")

        invisible(hera_dot_call("Comm__send", private$xp, js_metadata, js_data))
    },

    #' @param handler function to call when the comm is closed
    on_close = function(handler) {
        private$close_handler <- function(request) {
            handler(request)
            self$finalize()
        }
        invisible(hera_dot_call("Comm__on_close", private$xp, private$close_handler))
    },

    #' @param handler function to call when receiving a message
    on_message = function(handler) {
        private$message_handler <- handler
        invisible(hera_dot_call("Comm__on_message", private$xp, private$message_handler))
    },

    #' @return information about the comm
    print = function() {
      if (identical(description, "")) {
        writeLines(glue("<Comm id={self$id} target_name='{self$target_name}'>"))
      } else {
        writeLines(glue("<Comm id={self$id} target_name='{self$target_name}' description='{private$description}' >"))
      }
    },

    #' @return nothing
    finalize = function() {
        CommManager$release(self)
    }
  ),

  active = list(

    #' @field id
    #' id of the comm. read only.
    id = function() {
        hera_dot_call("Comm__id", private$xp)
    },

    #' @field target_name
    #' name of the target for this comm
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
