#' @import jsonlite
#' @import IRdisplay
NULL

utils <- NULL

.onLoad <- function(lib, pkg) {
  utils <<- asNamespace("utils")
  init_options()
}
