utils <- NULL

.onLoad <- function(lib, pkg) {
  utils <<- asNamespace("utils")
}
