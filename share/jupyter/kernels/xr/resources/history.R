history_df <- function(json) {
    if (length(json) == 0L) {
        json <- matrix(character(), nrow = 0, ncol = 4)
    }
    data.frame(
        session         = as.integer(json[, 1L]), 
        execution_count = as.integer(json[, 2L]),
        input           = json[, 3]
    )
}

history_tail <- function(n = 10L, raw = TRUE, output = TRUE, ...) {
    rlang::check_dots_empty()
    
    tail <- jsonlite::fromJSON(.Call("xeusr_history_get_tail", as.integer(n), raw, output, PACKAGE = "(embedding)"))
    history_df(tail$history)
}

history_search <- function(pattern = "*", raw = TRUE, output = FALSE, n = 10L, unique = FALSE, ...) {
    rlang::check_dots_empty()
    
    search <- jsonlite::fromJSON(.Call("xeusr_history_search", pattern, raw, output, as.integer(n), unique, PACKAGE = "(embedding)"))
    history_df(search$history)
}

history_range <- function(session = 0L, start, stop, raw = TRUE, output = FALSE, ...) {
    rlang::check_dots_empty()

    range <- jsonlite::fromJSON(.Call("xeusr_history_get_range", session, as.integer(start), as.integer(stop), raw, output, PACKAGE = "(embedding)"))
    if (range$status == "error") {
        stop(range$ename)
    }
    history_df(range$history)
}