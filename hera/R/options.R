cell_options <- function(...) {
  rlang::local_options(..., .frame = .env_private$frame_cell_execute)
}

get_null_device <- function() {
  os <- get_os()

  ok_device     <- switch(os, win = png,   osx = pdf,  unix = png)
  null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null')

  null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
  null_device
}

init_cran_mirror <- function() {
  repos <- getOption('repos')
  if (identical(repos, c(CRAN = '@CRAN@'))) {
    repos[['CRAN']] <- 'https://cran.r-project.org'
    options(repos = repos)
  }
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

}
