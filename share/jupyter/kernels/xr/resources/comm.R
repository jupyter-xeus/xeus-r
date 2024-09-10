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
            invisible(.Call("CommManager__register_target", target_name, PACKAGE = "(embedding)"))
        }, 

        unregister_comm_target = function(target_name) {
            rm(list = target_name, private$env_targets)
            invisible(.Call("CommManager__unregister_target", target_name, PACKAGE = "(embedding)"))
        }, 

        new_comm = function(target_name) {
            .Call("CommManager__new_comm", target_name, PACKAGE = "(embedding)")
        }, 

        comms = function() {
            as.list(private$env_comms)
        },

        target_callback = function(target_name) {
            private$env_targets[[target_name]]
        }, 

        preserve = function(comm) {
            assign(comm$id, comm, private$env_comms)
        }, 

        release = function(comm) {
            rm(list = comm$id, private$env_comms)
        }
    ), 

    private = list(
        env_targets = NULL, 
        env_comms = NULL
    )
)
CommManager <- CommManagerClass$new()

Comm <- R6::R6Class("Comm", 
    public = list(
        initialize = function(xp) {
            private$xp <- xp
            CommManager$preserve(self)
        }, 

        open = function(metadata = NULL, data = NULL, ...) {
            js_metadata <- jsonlite::toJSON(metadata, ...)
            js_data <- jsonlite::toJSON(data, ...)

            invisible(.Call("Comm__open", private$xp, js_metadata, js_data, PACKAGE = "(embedding)"))
        }, 

        close = function(metadata = NULL, data = NULL, ...) {
            js_metadata <- jsonlite::toJSON(metadata, ...)
            js_data <- jsonlite::toJSON(data, ...)

            invisible(.Call("Comm__close", private$xp, js_metadata, js_data, PACKAGE = "(embedding)"))
        }, 

        send = function(metadata = NULL, data = NULL, ...) {
            js_metadata <- jsonlite::toJSON(metadata, ...)
            js_data <- jsonlite::toJSON(data, ...)

            invisible(.Call("Comm__send", private$xp, js_metadata, js_data, PACKAGE = "(embedding)"))
        }, 

        on_close = function(handler) {
            private$close_handler <- handler
            invisible(.Call("Comm__on_close", private$xp, handler, PACKAGE = "(embedding)"))
            CommManager$release(self)
        }, 

        on_message = function(handler) {
            private$message_handler <- handler
            invisible(.Call("Comm__on_message", private$xp, handler, PACKAGE = "(embedding)"))
        }, 

        print = function() {
            writeLines(glue("<Comm id ={self$id} target_name = '{self$target_name}'>"))
        }
    ), 

    active = list(
        id = function() {
            .Call("Comm__id", private$xp, PACKAGE = "(embedding)")
        }, 

        target_name = function() {
            .Call("Comm__target_name", private$xp, PACKAGE = "(embedding)")
        }
    ),
    
    private = list(
        xp = NULL, 
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
            jsonlite::fromJSON(.Call("Message__get_content", private$xp, PACKAGE = "(embedding)"))
        }, 

        header = function() {
            jsonlite::fromJSON(.Call("Message__get_header", private$xp, PACKAGE = "(embedding)"))
        }, 

        parent_header = function() {
            jsonlite::fromJSON(.Call("Message__get_parent_header", private$xp, PACKAGE = "(embedding)"))
        }, 

        metadata = function() {
            jsonlite::fromJSON(.Call("Message__get_metadata", private$xp, PACKAGE = "(embedding)"))
        }
    ),

    private = list(
        xp = NULL
    )
)
