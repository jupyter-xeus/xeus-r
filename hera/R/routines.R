publish_stream <- function(name, text) {
  hera_dot_call("xeusr_publish_stream", name, text)
}

#' Display data
#'
#' @param data data to display
#' @param metadata potential metadata
#'
#' @examples
#' \dontrun{
#'   display_data(mtcars)
#' }
#'
#' @export
display_data <- function(data = NULL, metadata = NULL) {
  # Selectively unbox only single-element image MIME types to fix VS Code double-encoding
  # while keeping text types as arrays for test compatibility
  data_to_serialize <- data
  for (mime in names(data_to_serialize)) {
    if (grepl("^image/", mime) && length(data_to_serialize[[mime]]) == 1) {
      data_to_serialize[[mime]] <- jsonlite::unbox(data_to_serialize[[mime]])
    }
  }

  invisible(hera_dot_call("xeusr_display_data",
                          toJSON(data_to_serialize, auto_unbox = FALSE),
                          toJSON(metadata, auto_unbox = FALSE)))
}

update_display_data <- function(data = NULL, metadata = NULL) {
  # Selectively unbox only single-element image MIME types to fix VS Code double-encoding
  # while keeping text types as arrays for test compatibility
  data_to_serialize <- data
  for (mime in names(data_to_serialize)) {
    if (grepl("^image/", mime) && length(data_to_serialize[[mime]]) == 1) {
      data_to_serialize[[mime]] <- jsonlite::unbox(data_to_serialize[[mime]])
    }
  }

  invisible(hera_dot_call("xeusr_update_display_data",
                          toJSON(data_to_serialize, auto_unbox = FALSE),
                          toJSON(metadata, auto_unbox = FALSE)))
}

kernel_info_request <- function() {
  hera_dot_call("xeusr_kernel_info_request")
}


#' Clear output
#'
#' @param wait Should this wait
#'
#' @examples
#' \dontrun{
#'   clear_output()
#' }
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
#' @examples
#' \dontrun{
#'   View(mtcars)
#' }
#'
#' @export
View <- function(x, title) {
  if (!missing(title)) IRdisplay::display_text(title)
  IRdisplay::display(x)
  invisible(x)
}
