#' @export
mime_bundle.htmlwidget <- function(x, mimetypes = mime_types(x), ...) {
  data <- list()
  metadata <- list()

  if ("text/plain" %in% mimetypes) {
    data[["text/plain"]] <- "HTML widgets cannot be represented in plain text. This needs support for the application/vnd.xeus-r.htmlwidget+json mime type"
  }

  mime <- "application/vnd.xeus-r.htmlwidget+json"
  if (mime %in% mimetypes) {
    comm <- CommManager$new_comm("xeus-r.htmlwidget")
    # TODO: keep the widget somewhere
    comm$open(data = list(comm_id = comm$id))
    data[[mime]] <- list(comm_id = comm$id)
  }

  list(data = data, metadata = metadata)
}
