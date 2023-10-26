
publish_execution_error <- function(ename, evalue, trace_back = character()) {
  invisible(.Call("xeusr_publish_execution_error", ename, evalue, trace_back))
}

publish_execution_result <- function(execution_count, data, metadata = NULL) {
  invisible(.Call("xeusr_publish_execution_result", as.integer(execution_count), jsonlite::toJSON(data), jsonlite::toJSON(metadata)))
}

publish_stream <- function(name, text) {
  invisible(.Call("xeusr_publish_stream", name, text, PACKAGE = "(embedding)"))
}

display_data <- function(data = NULL, metadata = NULL) {
  .Call("xeusr_display_data", jsonlite::toJSON(data), jsonlite::toJSON(metadata))
}
