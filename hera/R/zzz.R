#' @importFrom grDevices pdf png
#' @importFrom jsonlite toJSON unbox
#' @importFrom utils head tail capture.output
#' @importFrom R6 R6Class
NULL

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

.onLoad <- function(libname, pkgname) {
  # - verify this is running within xeus-r
  # - handshake
  the <<- new.env()
  the$frame_cell_execute <- NULL

  ns_utils <- asNamespace("utils")
  get("unlockBinding", envir = baseenv())("print.vignette", ns_utils)

  assign("print.vignette", print_vignette, ns_utils)
  get("lockBinding", envir = baseenv())("print.vignette", ns_utils)

  init_options()
}

init_options <- function() {
  options(
    device = get_null_device(),
    cli.num_colors = 256L,
    jupyter.plot_mimetypes = c('text/plain', 'image/png'),
    jupyter.plot_scale = 2,

    jupyter.rich_display = TRUE,
    jupyter.base_display_func = display_data,
    jupyter.clear_output_func = clear_output
  )

  repos <- getOption('repos')
  if (identical(repos, c(CRAN = '@CRAN@'))) {
    repos[['CRAN']] <- 'https://cran.r-project.org'
    options(repos = repos)
  }
}

hera_call <- function(fn, ...) {
    get(fn, envir = NAMESPACE)(...)
}

hera_new <- function(class, xp) {
    get(class, envir = NAMESPACE)$new(xp)
}

is_xeus <- function() {
  embedding <- getLoadedDLLs()[["(embedding)"]]
  !is.null(embedding) && "xeusr_kernel_info_request" %in% getDLLRegisteredRoutines()$.Call
}

hera_dot_call <- function(fn, ...) {
  # TODO: check that we are indeed withing xeus-r
  # and have some sort of plan B

  # if (!is_xeusr()) {
  #   ...
  # }

  call <- rlang::call2(".Call", fn, ..., PACKAGE = "(embedding)")
  eval.parent(call)
}

get_null_device <- function() {
  os <- get_os()

  ok_device     <- switch(os, win = png,   osx = pdf,  unix = png, wasm = png)
  null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null', wasm = '/tmp/null')

  null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
  null_device
}

