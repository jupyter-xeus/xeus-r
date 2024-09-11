Layout <- R6::R6Class("jupyter.widget.Layout", 
    public = list(
        initialize = function() {
            comm <- CommManager$new_comm("jupyter.widget", "slider layout")
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

        comm = NULL, 

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
            "_model_module" = "@jupyter-widgets/base", 
            "_model_module_version" = "2.0.0", 
            "_model_name" = "LayoutModel", 
            "_view_count" = NULL, 
            "_view_module"= "@jupyter-widgets/base", 
            "_view_module_version" = "2.0.0", 
            "_view_name" = "LayoutView", 
            "align_content" = NULL, 
            "align_items" = NULL, 
            "align_self" = NULL, 
            "border_bottom" = NULL, 
            "border_left" = NULL, 
            "border_right" = NULL, 
            "border_top" = NULL, 
            "bottom" = NULL, 
            "display" = NULL, 
            "flex" = NULL, 
            "flex_flow" = NULL, 
            "grid_area" = NULL, 
            "grid_auto_columns" = NULL,
            "grid_auto_flow" = NULL, 
            "grid_auto_rows" = NULL, 
            "grid_column" = NULL, 
            "grid_gap" = NULL, 
            "grid_row" = NULL, 
            "grid_template_areas" = NULL, 
            "grid_template_columns" = NULL, 
            "grid_template_rows" = NULL, 
            "height" = NULL, 
            "justify_content" = NULL, 
            "justify_items" = NULL, 
            "left" = NULL, 
            "margin" = NULL, 
            "max_height" = NULL, 
            "max_width" = NULL, 
            "min_height" = NULL, 
            "min_width" = NULL, 
            "object_fit" = NULL, 
            "object_position" = NULL, 
            "order" = NULL, 
            "overflow" = NULL, 
            "padding" = NULL, 
            "right" = NULL, 
            "top" = NULL, 
            "visibility" = NULL, 
            "width" = NULL
        )
    )
)
