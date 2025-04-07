triple_colon <- function(pkg, fun) {
  eval(rlang::call2(":::", as.symbol(pkg), as.symbol(fun)))
}

utils___assignLineBuffer    <- triple_colon("utils", ".assignLinebuffer")
utils___assignEnd           <- triple_colon("utils", ".assignEnd")
utils___guessTokenFromLine  <- triple_colon("utils", ".guessTokenFromLine")
utils___completeToken       <- triple_colon("utils", ".completeToken")
utils___retrieveCompletions <- triple_colon("utils", ".retrieveCompletions")

#' Code completion
#'
#' @param code R code to complete
#' @param cursor_pos position of the cursor
#'
#' @examples
#' complete("rnorm(")
#'
#' @return a list that contains potential completions as the first item
#'
#' @export
complete <- function(code, cursor_pos = nchar(code)) {
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

    utils___assignLineBuffer(line)
    utils___assignEnd(cursor_pos)

    info <- utils___guessTokenFromLine(update = FALSE)
    utils___guessTokenFromLine()
    utils___completeToken()

    start_position <- chars_before_line + info$start
    comps <- utils___retrieveCompletions()

    list(
      comps,
      c(start_position, start_position + nchar(info$token))
    )
}
