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

cell_options <- function(...) {
  rlang::local_options(..., .frame = .xeusr_private_env$frame_cell_execute)
}

View <- function(x, title) {
  if (!missing(title)) IRdisplay::display_text(title)
  IRdisplay::display(x)
  invisible(x)
}

ns_utils <- asNamespace("utils")
unlockBinding("print.vignette", ns_utils)
print.vignette <- function(x, ...) {
  file <- x$PDF
  if (nzchar(file) == 0) {
    warning(gettextf("vignette %s has no PDF/HTML", sQuote(x$Topic)), call. = FALSE, domain = NA)
    return(invisible(x))
  }

  ext <- tolower(tools::file_ext(file))
  if (ext == "pdf") {
    warning("can't display pdf vignette yet")
    return(invisible(x))
  }

  if (ext == "html") {
    html <- readLines(file.path(x$Dir, "doc", file))

    display_data(
      data = list(
        "text/html" = paste(html, collapse = "\n")
      ), 
      metadata = list(
        "text/html" = list(isolated = TRUE)
      )
    )
  }

  invisible(x)
}
assign("print.vignette", print.vignette, ns_utils)
lockBinding("print.vignette", ns_utils)

get_comm_manager__size <- function() {
  .Call("xeusr_get_comm_manager__size", PACKAGE = "(embedding)")
}

comm_target_env <- new.env()

# TODO: callback should be a function that takes `comm` and `msg`
xeusr_comm_manager__register_target <- function(name, callback) {
  .Call("xeusr_comm_manager__register_target", name, PACKAGE = "(embedding)")
  comm_target_env[[name]] <- callback
}

xeusr_comm_manager__unregister_target <- function(name) {
  .Call("xeusr_comm_manager__unregister_target", name, PACKAGE = "(embedding)")
  comm_target_env[[name]] <- NULL
}

xeusr_comm_manager__comm_open <- function(target_name, data = NULL, comm_id = uuid::UUIDgenerate()) {
  .Call("xeusr_comm_manager__comm_open", comm_id, target_name, data, PACKAGE = "(embedding)")
}
