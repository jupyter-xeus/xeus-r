#' MIME types supported by an object
#'
#' @param x an object
#'
#' @return a character vector of its supported mime types
mime_types <- function(x) {
  UseMethod("mime_types")
}

#' @export
mime_types.default <- function(x) {
  "text/plain"
}

#' @export
mime_types.htmlwidget <- function(x) {
  c("text/plain", "text/html")
}

#' @export
mime_types.shiny.tag.list <- function(x) {
  c("text/plain", "text/html")
}

#' @export
mime_types.shiny.tag <- function(x) {
  c("text/plain", "text/html")
}


#' bundle an object
#'
#' @param x an object
#' @param mimetypes mime types
#' @param ... extra currently unused parameters
#'
#' @seealso IRdisplay::prepare_mimebundle which this currently wraps around
#'
#' @export
mime_bundle <- function(x, mimetypes = mime_types(x), ...) {
  UseMethod("mime_bundle")
}

#' @importFrom IRdisplay prepare_mimebundle
#' @export
mime_bundle.default <- function(x, mimetypes = mime_types(x), ...) {
  prepare_mimebundle(x, mimetypes = mimetypes, ...)
}
