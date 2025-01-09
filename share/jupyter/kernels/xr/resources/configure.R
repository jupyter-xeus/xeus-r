get_null_device <- function() {
  os <- get_os()

  ok_device     <- switch(os, win = png,   osx = pdf,  unix = png, wasm = pdf)
  null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null', wasm = NULL)

  null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
  null_device
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

configure <- function() {
  pos <- which(search() == "tools:xeusr")

  attachNamespace("IRdisplay", pos = pos + 1)
  attachNamespace("glue", pos = pos + 1)
  attachNamespace("jsonlite", pos = pos + 1)

  # setMethod(jsonlite:::asJSON, "shiny.tag", function(x, ...) {
  #   jsonlite:::asJSON(as.character(x), ...)
  # })

  init_options()
}
