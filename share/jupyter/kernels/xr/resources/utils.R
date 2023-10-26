# borrowed from IRkernel
get_os <- function() {
    switch(.Platform$OS.type,
        windows = 'win',
        unix = if (identical(Sys.info()[['sysname']], 'Darwin')) 'osx' else 'unix'
    )
}

# borrowed from IRkernel
plot_builds_upon <- function(prev, current) {
    if (is.null(prev)) {
        return(TRUE)
    }
    
    lprev <- length(prev[[1]])
    lcurrent <- length(current[[1]])
    
    lcurrent >= lprev && identical(current[[1]][1:lprev], prev[[1]][1:lprev])
}
