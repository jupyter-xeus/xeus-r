# borrowed from IRkernel
init_device_option <- function() {
    os <- get_os()
    
    ok_device     <- switch(os, win = png,   osx = pdf,  unix = png)
    null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null')
    
    null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
    
    options(device = null_device)
}

init <- function() {
  options("cli.num_colors" = 256L)
  init_device_option()
}
