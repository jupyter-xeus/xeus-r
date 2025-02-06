inspect <- function(code, cursor_pos) {
    # This is the approach used in IRkernel, it would perhaps 
    # be better to use parsing instead, e.g. with the internal R
    # parser, but the expression has to be complete, or a more 
    # forgiving parser, e.g. tree-sitter and the grammar for R:
    # https://github.com/r-lib/tree-sitter-r/tree/next

    # Get token under the `cursor_pos`.
    # Since `.guessTokenFromLine()` does not check the characters after `cursor_pos`
    # check them by a loop. Use get since R CMD check does not like :::
    token <- ''
    for (i in seq(cursor_pos, nchar(code))) {
        token_candidate <- utils:::.guessTokenFromLine(code, i)
        if (nchar(token_candidate) == 0) break
        token <- token_candidate
    }

    # Function to add a section to content.
    title_templates <- list(
        'text/plain' = '# %s:\n',
        'text/html' = '<h1>%s:</h1>\n'
    )
    
    add_new_section <- function(data, section_name, new_data) {
        for (mime in names(title_templates)) {
            new_content <- new_data[[mime]]
            if (is.null(new_content)) next
            title <- sprintf(title_templates[[mime]], section_name)
            # use paste0 since sprintf cannot deal with format strings > 8192 bytes
            data[[mime]] <- paste0(data[[mime]], title, new_content, '\n', sep = '\n')
        }
        return(data)
    }

    data <- namedlist()
    if (nchar(token) != 0) {
        # In many cases `get(token)` works, but it does not
        # in the cases such as `token` is a numeric constant or a reserved word.
        # Therefore `eval()` is used here.
        obj <- tryCatch(eval(parse(text = token), envir = .GlobalEnv), error = function(e) NULL)
        class_data <- if (!is.null(obj)) IRdisplay::prepare_mimebundle(class(obj))$data
        print_data <- if (!is.null(obj)) IRdisplay::prepare_mimebundle(obj)$data
        
        # `help(token)` is not used here because it does not works
        # in the cases `token` is in `pkg::topic`or `pkg:::topic` form.
        help_data <- tryCatch({
            help_obj <- eval(parse(text = paste0('?', token)))
            if (length(help_obj) > 0) {
                IRdisplay::prepare_mimebundle(help_obj)$data
            }
        }, error = function(e) NULL)
        
        # only show help if we have a function
        if ('function' %in% class(obj) && !is.null(help_data)) {
            data <- help_data
        } else {
            # any of those that are NULL are automatically skipped
            data <- add_new_section(data, 'Class attribute', class_data)
            data <- add_new_section(data, 'Printed form', print_data)
            data <- add_new_section(data, 'Help document', help_data)
        }
    }

    for (mime in names(data)) {
        data[[mime]] <- unbox(data[[mime]])
    }

    list(found = length(data) > 0L, data = toJSON(data), metadata = NULL)
}
