env_widgets <- new.env()

register_htmlwidget_handler <- function() {
  if (is_xeusr()) {
    # maybe the jupyter lab extension should register the target instead
    CommManager$register_comm_target("xeus-r.htmlwidget")
  }
}

HTMLWidget <- R6::R6Class(
  "HTMLWidget",

  private = list(
    dependencies = NULL
  ),

  public = list(
    widget = NULL,
    comm = NULL,

    initialize = function(widget) {
      self$widget <- widget

      # resolve dependencies
      # TODO: perhaps that can wait for the dependencies message ?
      dependencies <- htmltools::resolveDependencies(widget$dependencies)
      private$dependencies <- setNames(dependencies, vapply(dependencies, FUN.VALUE = character(1), \(dep) {
        paste(dep$name, dep$version, sep = "@")
      }))

      self$comm <- CommManager$new_comm("xeus-r.htmlwidget")

      self$comm$on_message(self$on_message)

      env_widgets[[self$comm$id]] <- self
      self$comm$open()
    },

    on_message = function(message) {
      data <- message$content$data
      switch(data$method,
        init         = self$on_init(),
        dependencies = self$on_dependencies(),
        dependency   = self$on_dependency(data),
        runtime      = self$on_runtime()
      )
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
      self$comm$send(
        data = list(
          method = "init",
          payload = repr::repr_html(self$widget)
        )
      )
    },

    on_dependencies = function() {

      payload <- lapply(private$dependencies, function(dep) {
        list(
          name = dep$name,
          version = dep$version
        )
      })

      self$comm$send(
        data = list(
          method = "dependencies",
          payload = unname(payload)
        )
      )
    },

    on_dependency = function(data) {
      key <- paste(data$name, data$version, sep = "@")

      dep <- private$dependencies[[key]]

      if (is.null(dep)) {
        stop("Unknown dependency: ", key)
      }

      root <- normalizePath(dep$src$file, mustWork = TRUE)
      paths <- c(dep$stylesheet, dep$script)

      files <- lapply(paths, \(path) {
        file <- normalizePath(file.path(root, path), mustWork = TRUE)
        content <- readBin(file, what = "raw", n = file.info(file)$size)

        list(
          path = path,
          content = content
        )
      })

      self$comm$send(data = list(
        method = "dependency",
        name = dep$name,
        version = dep$version,
        files = files
      ))

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
