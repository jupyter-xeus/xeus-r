
publish_execution_error <- function(ename, evalue, trace_back = character()) {
  .Call("xeusr_publish_execution_error", ename, evalue, trace_back, PACKAGE = "(embedding)")
}

publish_execution_result <- function(execution_count, data, metadata = NULL) {
  .Call("xeusr_publish_execution_result", as.integer(execution_count), jsonlite::toJSON(data), jsonlite::toJSON(metadata), PACKAGE = "(embedding)")
}

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
