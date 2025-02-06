# borrowed from IRkernel
get_os <- function() {
    switch(.Platform$OS.type,
        windows = 'win',
        unix = if (identical(Sys.info()[['sysname']], 'Darwin')) 'osx'
            else if (identical(Sys.info()[['sysname']], 'Emscripten')) 'wasm'
            else 'unix'
    )
}

namedlist <- function() {
    `names<-`(list(), character())
}

set_last_value <- function(obj, visible) {
    last_visible <<- visible

    unlockBinding(".Last.value", .BaseNamespaceEnv)
    assign(".Last.value", obj, .BaseNamespaceEnv)
    lockBinding(".Last.value", .BaseNamespaceEnv)
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
