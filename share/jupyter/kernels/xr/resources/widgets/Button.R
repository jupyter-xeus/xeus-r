ButtonStyle <- R6::R6Class("jupyter.widget.ButtonStyle", inherit = Style, 
    
    public = list(
        initialize = function() {
            super$initialize("button style")
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

ButtonModel <- R6::R6Class("jupyter.widget.ButtonModel", 
    public = list(
        comm = NULL, 

        initialize = function(layout, style) {
            comm <- CommManager$new_comm("jupyter.widget", "button model")
            comm$on_message(function(request) {
                method <- request$content$data$method
                
                if (method == "custom" && request$content$data$content$event == "click") {
                    handler <- private$handlers[["click"]]
                    if (!is.null(handler)) {
                        handler()
                    }
                }

            })

            comm$on_close(function(request) {})

            private$state_$layout <- glue("IPY_MODEL_{layout$comm$id}")
            private$state_$style <- glue("IPY_MODEL_{style$comm$id}")

            comm$open(
                data = list(state = private$state_, buffer_paths = list()), 
                metadata = list(version = "2.1.0")
            )
            self$comm <- comm

            private$handlers <- new.env()
        }, 

        state = function(what) {
            if (missing(what)) {
                private$state_
            } else {
                private$state_[[what]]
            }
        }, 

        on_click = function(handler = NULL) {
            private$handlers[["click"]] <- handler
        }
    ), 

    private = list(
        handlers = NULL,

        state_ = list(
            "_dom_classes" = list(), 
            "_model_module" = "@jupyter-widgets/controls",
            "_model_module_version" = "2.0.0", 
            "_model_name" = "ButtonModel", 
            "_view_count" = NULL, 
            "_view_module" = "@jupyter-widgets/controls", 
            "_view_module_version" = "2.0.0", 
            "_view_name" = "ButtonView", 
            "button_style" = "", 
            "description" = "Click Me", 
            "disabled" = FALSE, 
            "icon" = "", 
            "layout" = "IPY_MODEL_{layout}", 
            "style" = "IPY_MODEL_{style}", 
            "tabbable" = NULL, 
            "tooltip" = NULL
        )
    )
)

Button <- R6::R6Class("jupyter.widget.Button", inherit = Widget,
    public = list(
        layout = NULL, 
        style = NULL, 
        model = NULL,

        initialize = function() {
            self$layout <- Layout$new()
            self$style  <- ButtonStyle$new()
            self$model  <- ButtonModel$new(self$layout, self$style)
        }, 

        mime_bundle = function() {
            data <- list(
                "text/plain" = unbox(
                    glue("<Button id = {self$model$comm$id} >")
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

        on_click = function(handler) {
            self$model$on_click(handler)
        }
    )
)