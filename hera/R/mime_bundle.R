#' MIME types supported by an object
#'
#' @param x an object
#'
#' @examples
#' mime_types(letters)
#' mime_types(mtcars)
#'
#' @return a character vector of its supported mime types
#' @export
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

# R help objects. Without this, mime_types.default returns "text/plain", which
# repr::repr_text renders via tools::Rd2txt. Rd2txt emits nroff overstrike
# ("_\bX" underline, "X\bX" bold), and Jupyter's stdout stream does not
# interpret backspaces, so ?lm displays raw "_ l_ m" garbage. Advertising
# text/html lets the frontend pick the HTML rendering instead.
#' @export
mime_types.help_files_with_topic <- function(x) {
  c("text/plain", "text/html")
}

#' bundle an object
#'
#' @param x an object
#' @param mimetypes mime types
#' @param ... extra currently unused parameters
#'
#' @examples
#' mime_bundle(letters)
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
