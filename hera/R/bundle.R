#' bundle an object
#'
#' @inheritParams IRdisplay::prepare_mimebundle
#'
#' @seealso IRdisplay::prepare_mimebundle which this currently wraps around
#'
#' @export
bundle <- function(obj, mimetypes = getOption("jupyter.display_mimetypes"), ...) {
  UseMethod("bundle")
}

#' @importFrom IRdisplay prepare_mimebundle
#' @export
bundle.default <- function(obj, mimetypes = getOption("jupyter.display_mimetypes"), metadata = NULL, error_handler = stop) {
  prepare_mimebundle(obj, mimetypes = mimetypes, metadata = metadata, error_handler = error_handler)
}
