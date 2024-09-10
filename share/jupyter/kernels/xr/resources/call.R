.xeus_call <- function(fn, ...) {
    get(fn, envir = .xeus_env)(...)
}

.xeus_new <- function(class, xp) {
    get(class, envir = .xeus_env)$new(xp)
}
