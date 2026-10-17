env_widgets <- new.env()

register_htmlwidget_handler <- function() {
  if (is_xeusr()) {
    # maybe the jupyter lab extension should register the target instead
    CommManager$register_comm_target("xeus-r.htmlwidget")
  }
}

#' @export
HTMLWidget <- R6::R6Class(
  "HTMLWidget",

  private = list(
    dependencies = NULL, 
    input_callbacks = list()
  ),

  public = list(
    widget = NULL,
    comm = NULL,
    id = NULL,

    initialize = function(widget) {
      self$widget <- widget

      self$comm <- CommManager$new_comm("xeus-r.htmlwidget")

      self$comm$on_message(self$on_message)

      env_widgets[[self$comm$id]] <- self
      self$comm$open()
    },

    send_custom_message = function(type, message) {
      stopifnot(is.character(type), length(type) == 1L, !is.na(type))

      self$comm$send(list(
        method = "custom",
        type = type,
        message = message
      ))

      invisible(self)
    },

    on_message = function(message) {
      data <- message$content$data
      switch(data$method,
        init         = self$on_init(),
        dependencies = self$on_dependencies(),
        runtime      = self$on_runtime(), 
        initialized  = self$on_initialized(data),

        input        = self$handle_input(data$value)
      )
    },

    on_initialized = function(data) {
      self$id <- data$id
    },

    handle_input = function(data) {
      callbacks <- private$input_callbacks
      for (cb in callbacks) {
        cb(data)
      }
      invisible(NULL)
    },

    on_input = function(callback) {
      if (is.null(callback)) {
        # reset
        private$input_callbacks <- list()
      } else if (is.function(callback)) {
        # add
        private$input_callbacks[[length(private$input_callbacks) + 1L]] <- callback
      }

      invisible(self)
    },

    on_runtime = function() {
      path <- system.file("www", "htmlwidgets.js", package = "htmlwidgets")

      content <- readBin(
        path,
        what = "raw",
        n = file.info(path)$size
      )

      self$comm$send(data = list(
        method = "runtime",
        content = jsonlite::base64_enc(content)
      ))
    },

    on_init = function() {

      rendered <- htmltools::renderTags(
        htmltools::as.tags(self$widget)
      )
      self$comm$send(
        data = list(
          method = "init",
          payload = rendered$html
        )
      )
    },

    on_dependencies = function() {
      private$dependencies <- dependencies <- htmltools::resolveDependencies(self$widget$dependencies)
      
      scripts <- list()
      stylesheets <- list()

      for (dep in dependencies) {
        root <- dep$src$file
        
        for (path in dep$script) {
          resource <- read_resource(dep$name, dep$version, root, path)
          scripts <- append(scripts, list(resource))
        }

        for (path in dep$stylesheet) {
          resource <- read_resource(dep$name, dep$version, root, path)
          stylesheets <- append(stylesheets, list(resource))
        }
      }

      self$comm$send(data = list(
        method      = "dependencies",
        scripts     = unname(scripts),
        stylesheets = unname(stylesheets)
      ))

    }
  )
)

get_htmlwidget_model <- function(widget) {
  for (id in ls(env_widgets)) {
    model <- env_widgets[[id]]

    if (identical(model$widget, widget)) {
      return(model)
    }
  }
  
  NULL
}

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
    model <- get_htmlwidget_model(x)
    if (is.null(model)) {
      model <- HTMLWidget$new(x)
    }
    
    data[[mime]] <- list(comm_id = model$comm$id)
  }

  list(data = data, metadata = metadata)
}

read_resource <- function(name, version, src, path) {
  file <- file.path(src, path)
  list(
    name    = name,
    version = version,
    path    = path,
    content = jsonlite::base64_enc(
      readBin(file, "raw", n = file.info(file)$size)
    )
  )
}