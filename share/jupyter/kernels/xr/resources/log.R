
logger <- function(level, name) {
    function(...) {
        if (isTRUE(getOption('jupyter.log_level') >= level)) {
            msg <- glue::glue(...)
            .Call("xeusr_log", name, msg, PACKAGE = "(embedding)")
        }
        invisible(NULL)
    }
}

log_debug <- logger(3L, 'DEBUG')
log_info  <- logger(2L, 'INFO')
log_error <- logger(1L, 'ERROR')
