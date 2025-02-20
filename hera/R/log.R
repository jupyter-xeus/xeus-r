
logger <- function(level, name) {
    function(...) {
        if (isTRUE(getOption('jupyter.log_level') >= level)) {
            msg <- glue::glue(...)
            hera_dot_call("xeusr_log", name, msg)
        }
        invisible(NULL)
    }
}

log_debug <- logger(3L, 'DEBUG')
log_info  <- logger(2L, 'INFO')
log_error <- logger(1L, 'ERROR')
