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
