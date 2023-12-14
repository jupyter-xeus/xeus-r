history_tail <- function(n = 10L, raw = TRUE, output = TRUE, ...) {
    rlang::check_dots_empty()
    history <- jsonlite::fromJSON(.Call("xeusr_history_get_tail", as.integer(n), raw, output, PACKAGE = "(embedding)"))$history
    if (length(history) == 0L) {
        history <- matrix(character(), nrow = 0, ncol = 4)
    }
    data.frame(
        session         = history[, 1L], 
        execution_count = as.integer(history[, 2L]),
        input           = history[, 3]
    )
}

history_search <- function(...) {
    rlang::check_dots_empty()
    list(...)
}

history_range <- function(...) {
    list(...)
}