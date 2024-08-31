get_comm_manager__size <- function() {
  .Call("xeusr_get_comm_manager__size", PACKAGE = "(embedding)")
}

comm_target_env <- new.env()

xeusr_comm_manager__register_target <- function(name, callback) {
  comm_target_env[[name]] <- callback
  .Call("xeusr_comm_manager__register_target", name, PACKAGE = "(embedding)")
}

xeusr_comm_manager__unregister_target <- function(name) {
  .Call("xeusr_comm_manager__unregister_target", name, PACKAGE = "(embedding)")
  rm(list = name, comm_target_env)
}

xeusr_comm_manager__comm_open <- function(target_name, data = NULL) {
  .Call("xeusr_comm_manager__comm_open", target_name, jsonlite::toJSON(data), PACKAGE = "(embedding)")
}

comm_target_handle_comm_open <- function(target_name, js_content) {
    content <- jsonlite::fromJSON(js_content)
    comm_id <- content$comm_id

    target_callback <- comm_target_env[[target_name]]

    target_callback(comm_id, content)
}
