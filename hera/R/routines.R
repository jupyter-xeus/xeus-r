publish_stream <- function(name, text) {
  hera_dot_call("xeusr_publish_stream", name, text)
}

#' Display data
#'
#' @param data data to display
#' @param metadata potential metadata
#'
#' @export
display_data <- function(data = NULL, metadata = NULL) {
  invisible(hera_dot_call("xeusr_display_data", toJSON(data), toJSON(metadata)))
}

update_display_data <- function(data = NULL, metadata = NULL) {
  invisible(hera_dot_call("xeusr_update_display_data", toJSON(data), toJSON(metadata)))
}

kernel_info_request <- function() {
  hera_dot_call("xeusr_kernel_info_request")
}


#' Clear output
#'
#' @param wait Should this wait
#'
#' @return NULL invisibly
#' @export
clear_output <- function(wait = FALSE) {
  invisible(hera_dot_call("xeusr_clear_output", isTRUE(wait)))
}

is_complete_request <- function(code) {
  hera_dot_call("xeusr_is_complete_request", code)
}

#' View
#'
#' @param x something to display
#' @param title title of the display
#'
#' @export
View <- function(x, title) {
  if (!missing(title)) IRdisplay::display_text(title)
  IRdisplay::display(x)
  invisible(x)
}

xeusr_input <- function(prompt) {
  hera_dot_call("xeusr_input", prompt)
}

xeusr_getpass <- function(prompt) {
  hera_dot_call("xeusr_getpass", prompt)
}
