#' @export
asJSON.shiny.tag <- function(x, ...) {
  jsonlite:::asJSON(as.character(x), ...)
}
