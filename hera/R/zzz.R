NAMESPACE <- environment()
the <- new.env()
the$frame_cell_execute <- NULL

.onLoad <- function(libname, pkgname) {
  # - verify this is running within xeus-r
  # - handshake

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
  dlls <- getLoadedDLLs()
  embeding <- dlls[["(embedding)"]]
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

