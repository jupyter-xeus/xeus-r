inspect <- function(code, cursor_pos) {
    txt <- glue::glue("hola {Sys.time()}")
    data <- jsonlite::toJSON(list(
        'text/plain' = jsonlite::unbox(txt), 
        'text/html' = jsonlite::unbox(glue::glue("<h2>{txt}</h2>"))
    ))
    metadata <- NULL
    list(found = TRUE, data = data, metadata = metadata)
}
