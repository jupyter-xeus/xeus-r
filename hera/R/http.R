.hera_http <- new.env(parent = emptyenv())
.hera_http$server <- NULL
.hera_http$port <- NULL
.hera_http$paths <- list()

#' Start Hera's HTTP server
#'
#' Starts one loopback HTTP server per R process. Repeated calls return
#' the same base URL. The URL is reachable from the kernel host; remote
#' JupyterLab clients require an appropriate proxy.
#' 
#' @rdname http
#' @export
http_start <- function() {
  if (!is.null(.hera_http$server)) {
    return(sprintf("http://127.0.0.1:%d", .hera_http$port))
  }

  port <- httpuv::randomPort()
  app <- list(
    call = function(req) {
      list(status = 404L, headers = list("Content-Type" = "text/plain"),
           body = "Not found")
    },
    staticPaths = list()
  )
  server <- httpuv::startServer("127.0.0.1", port, app)
  if (length(.hera_http$paths) > 0L) {
    server$setStaticPath(.list = .hera_http$paths)
  }
  .hera_http$server <- server
  .hera_http$port <- port
  sprintf("http://127.0.0.1:%d", port)
}

#' Register a directory of static HTTP resources
#' @param prefix Single URL path segment, e.g. "leaflet".
#' @param directory Existing local directory.
#'
#' @rdname http
#' @export
http_add_resource_path <- function(prefix, directory) {
  if (!is.character(prefix) || length(prefix) != 1L || is.na(prefix) ||
      !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", prefix) ||
      prefix %in% c(".", "..")) {
    stop("`prefix` must be a single safe URL path segment.", call. = FALSE)
  }
  if (!is.character(directory) || length(directory) != 1L ||
      is.na(directory) || !dir.exists(directory)) {
    stop("`directory` must be an existing directory.", call. = FALSE)
  }
  directory <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  if (is.null(.hera_http$paths[[prefix]])) {
    path <- httpuv::staticPath(directory, indexhtml = FALSE)
    .hera_http$paths[[prefix]] <- path

    if (!is.null(.hera_http$server)) {
        .hera_http$server$setStaticPath(.list = .hera_http$paths)
    }

  }
  
  invisible(prefix)
}

#' Build a URL for a registered static resource
#' @param path Relative path beginning with the registered prefix.
#' 
#' @rdname http
#' @export
http_url <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      startsWith(path, "/") || grepl("[?#]", path) ||
      any(strsplit(path, "/", fixed = TRUE)[[1L]] %in% c("", ".", ".."))) {
    stop("`path` must be a safe relative resource path.", call. = FALSE)
  }
  parts <- strsplit(path, "/", fixed = TRUE)[[1L]]
  if (is.null(.hera_http$paths[[parts[[1L]]]])) {
    stop("Resource prefix is not registered: ", parts[[1L]], call. = FALSE)
  }
  base <- http_start()
  encoded <- vapply(parts, utils::URLencode, character(1), reserved = TRUE)
  paste0(base, "/", paste(encoded, collapse = "/"))
}

#' Stop Hera's HTTP server and clear resource registrations
#' 
#' @rdname http
#' @export
http_stop <- function() {
  if (!is.null(.hera_http$server)) {
    .hera_http$server$stop()
  }
  .hera_http$server <- NULL
  .hera_http$port <- NULL
  .hera_http$paths <- list()
  invisible(NULL)
}
