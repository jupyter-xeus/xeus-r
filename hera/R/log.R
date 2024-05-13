
logger <- function(level, name) {
  function(...) {
    if (isTRUE(getOption('jupyter.log_level') >= level)) {
      msg <- glue::glue(...)
      LOG(name, msg)
    }
    invisible(NULL)
  }
}

log_debug <- logger(3L, 'DEBUG')
log_info  <- logger(2L, 'INFO')
log_error <- logger(1L, 'ERROR')
