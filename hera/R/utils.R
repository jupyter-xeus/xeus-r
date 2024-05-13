# borrowed from IRkernel
get_os <- function() {
  switch(
    .Platform$OS.type,
    windows = 'win',
    unix = if (identical(Sys.info()[['sysname']], 'Darwin')) 'osx' else 'unix'
  )
}

namedlist <- function() {
  `names<-`(list(), character())
}

set_last_value <- function(obj, visible) {
  .env_private$last_visible <- visible

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

init_overwritten <- function() {
  unlockBinding("print.vignette", utils)
  unlockBinding("View", utils)
  print_vignette <- function(x, ...) {
    file <- x$PDF
    if (nzchar(file) == 0) {
      warning(gettextf("vignette %s has no PDF/HTML", sQuote(x$Topic)), call. = FALSE, domain = NA)
      return(invisible(x))
    }

    ext <- tolower(tools::file_ext(file))
    if (ext == "pdf") {
      warning("can't display pdf vignette yet")
      return(invisible(x))
    }

    if (ext == "html") {
      html <- readLines(file.path(x$Dir, "doc", file))

      display_data(
        data = list(
          "text/html" = paste(html, collapse = "\n")
        ),
        metadata = list(
          "text/html" = list(isolated = TRUE)
        )
      )
    }

    invisible(x)
  }
  assign("print.vignette", print_vignette, utils)
  lockBinding("print.vignette", utils)

  View <- function(x, title) {
    if (!missing(title)) IRdisplay::display_text(title)
    IRdisplay::display(x)
    invisible(x)
  }
  assign("View", View, utils)
  lockBinding("View", utils)
}
