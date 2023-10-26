get_null_device <- function() {
  os <- get_os()
  
  ok_device     <- switch(os, win = png,   osx = pdf,  unix = png)
  null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null')
  
  null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
  null_device
}

init_options <- function() {
  options(
    device = get_null_device(), 
    cli.num_colors = 256L, 
    jupyter.plot_mimetypes = c('text/plain', 'image/png'), 
    jupyter.plot_scale = 2
  )
}

configure <- function() {
  init_options()
}
