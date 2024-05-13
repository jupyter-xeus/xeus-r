publish_stream <- function(name, text) {
  .Call("xeusr_publish_stream", name, text, PACKAGE = "(embedding)")
}

display_data <- function(data = NULL, metadata = NULL) {
  invisible(.Call("xeusr_display_data", jsonlite::toJSON(data), jsonlite::toJSON(metadata), PACKAGE = "(embedding)"))
}

update_display_data <- function(data = NULL, metadata = NULL) {
  invisible(.Call("xeusr_update_display_data", jsonlite::toJSON(data), jsonlite::toJSON(metadata), PACKAGE = "(embedding)"))
}

kernel_info_request <- function() {
  .Call("xeusr_kernel_info_request", PACKAGE = "(embedding)")
}

clear_output <- function(wait = FALSE) {
  invisible(.Call("xeusr_clear_output", isTRUE(wait), PACKAGE = "(embedding)"))
}

is_complete_request <- function(code) {
  .Call("xeusr_is_complete_request", code, PACKAGE = "(embedding)")
}

LOG <- function(name, msg) {
  invisible(.Call("xeusr_log", name, msg, PACKAGE = "(embedding)"))
}
