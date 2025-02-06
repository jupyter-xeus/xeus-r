NAMESPACE <- environment()

.onLoad <- function(libname, pkgname) {
  # - verify this is running within xeus-r
  # - handshake
}

hera_call <- function(fn, ...) {
    get(fn, envir = NAMESPACE)(...)
}

hera_new <- function(class, xp) {
    get(class, envir = NAMESPACE)$new(xp)
}

is_xeus <- function() {
  dlls <- getLoadedDLLs()
  embeding <- dlls[["(embedding)"]]
  !is.null(embedding) && "xeusr_kernel_info_request" %in% getDLLRegisteredRoutines()$.Call
}

hera_dot_call <- function(fn, ...) {
  # TODO: check that we are indeed withing xeus-r
  # and have some sort of plan B

  # if (!is_xeusr()) {
  #   ...
  # }

  call <- rlang::call2(".Call", fn, ..., PACKAGE = "(embedding)")
  eval.parent(call)
}


