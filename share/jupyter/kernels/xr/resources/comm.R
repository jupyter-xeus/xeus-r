CommManager__register_target_callback <- function(comm_id, xp_request) {
    js_content <- .Call("xeusr_xmessage__get_content", xp_request, PACKAGE = "(embedding)")
    content <- jsonlite::fromJSON(js_content)
    
    target_name <- content$target_name
    target_callback <- comm_target_env[[target_name]]

    comm <- CommManager$get_comm(comm_id)

    # TODO: target_callback called with request, not content
    target_callback(comm, content)
}

CommManagerClass <- R6Class("CommManagerClass", 
    public = list(
        initialize = function() {
            private$targets <- new.env()
            private$comms <- new.env()
        },

        register_comm_target = function(target_name, callback) {
            private$targets[[name]] <- callback
            .Call("CommManager__register_target", target_name, PACKAGE = "(embedding)")
        }, 

        unregister_comm_target = function(target_name) {
            rm(list = target_name, private$targets)
            .Call("CommManager__unregister_target", target_name, PACKAGE = "(embedding)")
        }, 

        get_comm = function(id) {
            xp <- .Call("CommManager__get_comm", id, PACKAGE = "(embedding)")
            Comm$new(xp = xp)
        }, 

        new_comm = function(target_name) {
            xp <- .Call("CommManager__new_comm", target_name, PACKAGE = "(embedding)")
            Comm$new(xp = xp)
        }
    ), 

    private = list(
        targets = NULL
    )
)
CommManager <- CommManagerClass$new()

Comm <- R6Class("Comm", 
    public = list(
        id = character(),
        target_name = character(),

        initialize = function(xp) {
            private$xp <- xp
            self$id <- .Call("Comm__id", xp, PACKAGE = "(embedding)")
            self$target_name <- .Call("Comm__target_name", xp, PACKAGE = "(embedding)")
        }
        
    ), 
    
    private = list(
        xp = NULL
    )
)
