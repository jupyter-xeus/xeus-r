publish_stream <- function(name, text) {
  hera_dot_call("xeusr_publish_stream", name, text)
}

display_data <- function(data = NULL, metadata = NULL) {
  invisible(hera_dot_call("xeusr_display_data", jsonlite::toJSON(data), jsonlite::toJSON(metadata)))
}

update_display_data <- function(data = NULL, metadata = NULL) {
  invisible(hera_dot_call("xeusr_update_display_data", jsonlite::toJSON(data), jsonlite::toJSON(metadata)))
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

View <- function(x, title) {
  if (!missing(title)) IRdisplay::display_text(title)
  IRdisplay::display(x)
  invisible(x)
}
