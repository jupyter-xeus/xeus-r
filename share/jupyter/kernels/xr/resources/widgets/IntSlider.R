IntSliderStyle <- R6::R6Class("jupyter.widget.IntSliderStyle", inherit = Style,
    public = list(
        initialize = function() {
            super$initialize("slider style")
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

IntSliderModel <- R6::R6Class("jupyter.widget.IntSliderModel", inherit = Model,
    public = list(
        comm = NULL, 

        initialize = function(layout, style) {
            super$initialize(layout, style, "slider model")
        }
    ), 

    private = list(
        state_ = list(
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

IntSlider <- R6::R6Class("jupyter.widget.IntSlider", inherit = Widget,
    public = list(
        layout = NULL, 
        style = NULL, 
        model = NULL,

        initialize = function() {
            self$layout <- Layout$new()
            self$style  <- IntSliderStyle$new()
            self$model  <- IntSliderModel$new(self$layout, self$style)
        }, 

        mime_bundle = function() {
            data <- list(
                "text/plain" = unbox(
                    glue("<IntSlider id = {self$model$comm$id} value={self$model$state('value')})>")
                ), 
                "application/vnd.jupyter.widget-view+json" = list(
                    "version_major" = unbox(2L), 
                    "version_minor" = unbox(0L), 
                    "model_id" = unbox(self$model$comm$id)
                )
            )
            list(data = data, metadata = namedlist())
        }, 

        state = function(what) {
            self$model$state(what)
        }, 

        on_update = function(handler) {
            self$model$on_update(handler)
        }, 

        update = function(...) {
            self$model$update(...)
        }
    )
)
