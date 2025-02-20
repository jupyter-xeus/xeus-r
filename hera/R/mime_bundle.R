#' bundle an object
#'
#' @inheritParams IRdisplay::prepare_mimebundle
#' @param ... extra currently unused parameters
#'
#' @seealso IRdisplay::prepare_mimebundle which this currently wraps around
#'
#' @export
mime_bundle <- function(obj, mimetypes = getOption("jupyter.display_mimetypes"), ...) {
  UseMethod("mime_bundle")
}

#' @importFrom IRdisplay prepare_mimebundle
#' @export
mime_bundle.default <- function(obj, mimetypes = "text/plain", ...) {
  prepare_mimebundle(obj, mimetypes = mimetypes, ...)
}

#' @export
mime_bundle.htmlwidget <- function(obj, mimetypes = c("text/plain", "text/html"), ...) {
  prepare_mimebundle(obj, mimetypes = mimetypes, ...)
}

#' @export
mime_bundle.shiny.tag.list <- function(obj, mimetypes = c("text/plain", "text/html"), ...) {
  prepare_mimebundle(obj, mimetypes = mimetypes, ...)
}

#' @export
mime_bundle.shiny.tag <- function(obj, mimetypes = c("text/plain", "text/html"), ...) {
  prepare_mimebundle(obj, mimetypes = mimetypes, ...)
}
