ButtonStyle <- R6::R6Class("jupyter.widget.ButtonStyle", 
    public = list(
        comm = NULL, 

        initialize = function() {
            comm <- CommManager$new_comm("jupyter.widget", "button style")
            comm$on_message(function(request) {
                
            })
            comm$on_close(function(request) {
                
            })

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
    ), 

    private = list(
        state_ = list(
            "_model_module" = "@jupyter-widgets/controls", 
            "_model_module_version" = "2.0.0", 
            "_model_name" = "ButtonStyleModel", 
            "_view_count" = NULL, 
            "_view_module" = "@jupyter-widgets/base", 
            "_view_module_version" = "2.0.0", 
            "_view_name" = "StyleView", 
            "button_color" = NULL, 
            "font_family" = NULL, 
            "font_size" = NULL, 
            "font_style" = NULL, 
            "font_variant" = NULL,
            "font_weight" = NULL, 
            "text_color" = NULL, 
            "text_decoration" = NULL
        )
    )
)
