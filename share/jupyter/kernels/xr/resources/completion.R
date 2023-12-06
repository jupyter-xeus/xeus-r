# This is mostly inspired from IRkernel::completions()
complete <- function(code, cursor_pos = nchar(code)) {
    # ---- TODO: this should be done on the C++ side 

    # Find which line we're on and position within that line
    lines <- strsplit(code, '\n', fixed = TRUE)[[1]]
    chars_before_line <- 0L
    for (line in lines) {
        new_cursor_pos <- cursor_pos - nchar(line) - 1L # -1 for the newline
        if (new_cursor_pos < 0L) {
            break
        }
        cursor_pos <- new_cursor_pos
        chars_before_line <- chars_before_line + nchar(line) + 1L
    }

    # guard from errors when completion is invoked in empty cells 
    if (is.null(line)) {
        line <- ''
    }

    utils:::.assignLinebuffer(line)
    utils:::.assignEnd(cursor_pos)

    info <- utils:::.guessTokenFromLine(update = FALSE)
    utils:::.guessTokenFromLine()
    utils:::.completeToken()

    start_position <- chars_before_line + info$start
    comps <- utils:::.retrieveCompletions()

    # TODO: use jsonlite::toJSON() here
    list(comps, c(start_position, start_position + nchar(info$token)))

}