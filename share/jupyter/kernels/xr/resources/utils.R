get_os <- function() {
    switch(.Platform$OS.type,
        windows = 'win',
        unix = if (identical(Sys.info()[['sysname']], 'Darwin')) 'osx' else 'unix'
    )
}


