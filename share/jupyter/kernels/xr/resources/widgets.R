
handler_jupyter.widget.control <- function(comm, message) {
    
    comm$on_message(function(request) {
        data <- request$content$data

        switch(data$method, 
            "request_states" = {
                comm$send(
                    data = list(
                        method = unbox("update_states"), 
                        states = NULL
                    )
                )
            }
        )
    })
}

handler_jupyter.widget <- function(comm, message) {
    comm$on_message(function(request) {
    
    })
}

init_widgets <- function() {
    CommManager$register_comm_target("jupyter.widget.control", handler_jupyter.widget.control)
    CommManager$register_comm_target("jupyter.widget", handler_jupyter.widget)
}


IntSlider <- R6::R6Class("jupyter.widget.IntSlider", 
    public = list(
        initialize = function(...) {
            private$comm <- CommManager$new_comm("jupyter.widget")

            private$comm$on_message(function(request) {
                # TODO: when receiing message from front end
                
                # method <- request$content$data$method
                # ...
            })

            private$comm$on_close(function(request) {
                # TODO
            })

            dots <- list(...)
            states <- replace(private$defaults, names(dots), dots)
            
            data <- list(
                data = list(
                    states = states, 
                    buffer_paths = list()
                )
            )
            private$comm$open(data = data, auto_unbox = TRUE, null = "null")
        }
    ), 

    private = list(
        comm = NULL, 
        defaults = list(
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

