env_widgets <- new.env()

register_htmlwidget_handler <- function() {
  if (is_xeusr()) {
    # maybe the jupyter lab extension should register the target instead
    CommManager$register_comm_target("xeus-r.htmlwidget")
  }
}

HTMLWidget <- R6::R6Class(
  "HTMLWidget",
  public = list(
    widget = NULL,
    comm = NULL,

    initialize = function(widget) {
      self$widget <- widget
      self$comm <- CommManager$new_comm("xeus-r.htmlwidget")

      self$comm$on_message(self$on_message)

      env_widgets[[self$comm$id]] <- self
      self$comm$open()
    }, 

    on_message = function(message) {
      data <- message$content$data 
      switch(data$method, 
        init = self$on_init()
      )
    },

    on_init = function() {
      self$comm$send(
        data = list(
          method = "init", 
          payload = repr::repr_html(self$widget)
        )
      )
    }
  )
)

#' @export
mime_types.htmlwidget <- function(x) {
  c("text/plain", "application/vnd.jupyter.r-htmlwidget+json")
}

#' @export
mime_bundle.htmlwidget <- function(x, mimetypes = mime_types(x), ...) {
  data <- list()
  metadata <- list()

  if ("text/plain" %in% mimetypes) {
    data[["text/plain"]] <- "HTML widget requires support for application/vnd.jupyter.r-htmlwidget+json"
  }

  mime <- "application/vnd.jupyter.r-htmlwidget+json"
  if (mime %in% mimetypes) {
    model <- HTMLWidget$new(x)
    data[[mime]] <- list(comm_id = model$comm$id)
  }

  list(data = data, metadata = metadata)
}
