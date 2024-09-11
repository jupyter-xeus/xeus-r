IntSliderStyle <- R6::R6Class("jupyter.widget.IntSliderStyle", 
    public = list(
        comm = NULL, 

        initialize = function() {
            comm <- CommManager$new_comm("jupyter.widget", "slider style")
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

IntSlider <- R6::R6Class("jupyter.widget.IntSlider", inherit = Widget,
    public = list(
        initialize = function() {
            private$layout <- Layout$new()
            private$style  <- IntSliderStyle$new()

            private$comm_slider <- private$initialise_comm_slider()
        }, 

        mime_bundle = function() {
            data <- list(
                "text/plain" = unbox(
                    glue("<IntSlider id = {private$comm_slider$id} value={private$states_slider$value})>")
                ), 
                "application/vnd.jupyter.widget-view+json" = list(
                    "version_major" = unbox(2L), 
                    "version_minor" = unbox(0L), 
                    "model_id" = unbox(private$comm_slider$id)
                )
            )
            list(data = data, metadata = namedlist())
        }, 

        state = function(what) {
            private$states_slider[[what]]
        },

        finalize = function() {
            private$comm_slider <- NULL
        }
    ), 

    private = list(
        layout = NULL,
        style = NULL,

        comm_slider = NULL,

        initialise_comm_slider = function() {
            comm_slider <- CommManager$new_comm("jupyter.widget", "slider model")
            comm_slider$on_message(function(request) {
                
                switch(
                    request$content$data$method, 
                    update = {
                        state <- request$content$data$state
                        private$states_slider <- replace(private$states_slider, names(state), state)

                        comm_slider$send(
                            data = list(method = "echo_update", state = state, buffer_paths = list())
                        )
                    }
                )

            })

            comm_slider$on_close(function(request) {
                writeLines(glue("comm slider closed {comm_slider$id}"))
            })

            private$states_slider$layout <- glue("IPY_MODEL_{private$layout$comm$id}")
            private$states_slider$style <- glue("IPY_MODEL_{private$style$comm$id}")

            comm_slider$open(
                data = list(state = private$states_slider, buffer_paths = list()), 
                metadata = list(version = "2.1.0")
            )
            comm_slider
        },

        states_slider = list(
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
