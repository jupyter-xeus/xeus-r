Style <- R6::R6Class("jupyter.widget.Style", 
    public = list(
        comm = NULL, 

        initialize = function(description) {
            comm <- CommManager$new_comm("jupyter.widget", description)
            
            comm$open(
                data = list(state = private$state_, buffer_paths = list()), 
                metadata = list(version = "2.1.0")
            )
            
            self$comm <- comm
        }, 

        state = function(what) {
            if (missing(what)) {
                private$state_
            } else {
                private$state_[[what]]
            }
        }
    )
)
