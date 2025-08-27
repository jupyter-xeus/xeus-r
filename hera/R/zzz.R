#' @importFrom grDevices pdf png
#' @importFrom jsonlite toJSON unbox fromJSON
#' @importFrom utils head tail capture.output
#' @importFrom R6 R6Class
#' @importFrom rlang caller_env
#' @import glue
NULL

print_vignette <- function(x, ...) {
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

NAMESPACE <- environment()
the <- NULL

.onLoad <- function(libname, pkgname) {
    # - verify this is running within xeus-r
    # - handshake
    NAMESPACE$the <- new.env()
    the$frame_cell_execute <- NULL
    the$last_plot <- NULL
    the$last_visible <- TRUE
    the$last_error <- NULL

    ns_utils <- asNamespace("utils")
    get("unlockBinding", envir = baseenv())("print.vignette", ns_utils)

    assign("print.vignette", print_vignette, ns_utils)
    get("lockBinding", envir = baseenv())("print.vignette", ns_utils)

    NAMESPACE$CommManager <- CommManagerClass$new()

    init_options()

    if(R.version$platform == "wasm32-unknown-emscripten") {

        ###################################################
        # download.file
        ###################################################
        utils_ns <- asNamespace("utils")
        utils_pkg <- as.environment("package:utils")
        for (env in list(utils_ns, utils_pkg)) {
            get("unlockBinding", envir = baseenv())("download.file", env)
            assign("download.file", xeus_download_file, envir = env)
            get("lockBinding", envir = baseenv())("download.file", env)
        }

        ###################################################
        # url
        ###################################################
        base_ns <- asNamespace("base")
        base_pkg <- as.environment("package:base")
        for (env in list(base_ns, base_pkg)) {
            get("unlockBinding", envir = baseenv())("url", env)
            assign("url", xeus_url, envir = env)
            get("lockBinding", envir = baseenv())("url", env)
        }

        ###################################################
        # file
        ###################################################
        base_ns <- asNamespace("base")
        base_pkg <- as.environment("package:base")
        for (env in list(base_ns, base_pkg)) {
            get("unlockBinding", envir = baseenv())("file", env)
            assign("file", xeus_file, envir = env)
            get("lockBinding", envir = baseenv())("file", env)
        }
    }
   
}

init_options <- function() {
  options(
    device = get_null_device(),
    cli.num_colors = 256L,
    jupyter.plot_mimetypes = c('text/plain', 'image/png'),
    jupyter.plot_scale = 2,

    jupyter.rich_display = TRUE,
    jupyter.base_display_func = display_data,
    jupyter.clear_output_func = clear_output
  )

  repos <- getOption('repos')
  if (identical(repos, c(CRAN = '@CRAN@'))) {
    repos[['CRAN']] <- 'https://cran.r-project.org'
    options(repos = repos)
  }
}

NAMESPACE <- environment()
hera_call <- function(fn, ...) {
    get(fn, envir = NAMESPACE)(...)
}

hera_new <- function(class, xp, ...) {
    get(class, envir = NAMESPACE)$new(xp, ...)
}

#' Is this a running xeusr jupyter kernel
#'
#' @return TRUE if the current session is running in a xeusr kernel
#'
#' @examples
#' is_xeusr()
#'
#' @export
is_xeusr <- function() {
  embedding <- getLoadedDLLs()[["(embedding)"]]
  !is.null(embedding) && "xeusr_kernel_info_request" %in% names(getDLLRegisteredRoutines(embedding)$.Call)
}

hera_dot_call <- function(fn, ..., error_call = caller_env()) {
  call <- rlang::call2(".Call", fn, ..., PACKAGE = "(embedding)")

  if (!is_xeusr()) {
    cli::cli_abort(c(
      "The {.val {fn}} routine must be called inside a xeusr kernel.",
      i   = "Full internal call to the xeusr routine:",
      " " = "{deparse(call)}"
    ), call = error_call)
  }
  eval.parent(call)
}

get_null_device <- function() {
  os <- get_os()

  ok_device     <- switch(os, win = png,   osx = pdf,  unix = png, wasm = png)
  null_filename <- switch(os, win = 'NUL', osx = NULL, unix = '/dev/null', wasm = '/tmp/null')

  null_device <- function(filename = null_filename, ...) ok_device(filename, ...)
  null_device
}

#' @importFrom IRdisplay display
#' @export
IRdisplay::display
