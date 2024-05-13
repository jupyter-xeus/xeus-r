#' @import jsonlite
#' @import IRdisplay
NULL

utils <- NULL

.onLoad <- function(lib, pkg) {
  utils <<- asNamespace("utils")
  init_options()
  init_overwritten()

  dlls <- getLoadedDLLs()
  if (!"(embedding)" %in% names(dlls)) {
    packageStartupMessage("hera is meant to be loaded from within xeusr")
  } else {
    dot_call <- names(getDLLRegisteredRoutines("(embedding)")$.Call)
    if (! "xeusr_kernel_info_request" %in% dot_call) {
      packageStartupMessage("hera is meant to be loaded from within xeusr")
    }
  }
}
