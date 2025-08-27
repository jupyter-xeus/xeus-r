original_file <- base::file

xeus_download_file <- function(
    url, 
    destfile,
    method = "auto",
    quiet = FALSE,
    mode = "w",
    cacheOK = TRUE,
    extra =  getOption("download.file.extra"),
    headers = NULL
)
{
    # if the method is not "auto" or "internal" we warn, but still try
    # to continue with the download
    if (method != "auto" && method != "internal" && method != "default") {
        warning(gettextf("download.file method '%s' is not supported in xeus-r-lite, trying to continue with internal method", method), call. = FALSE)
    } 

    # if cacheOK is FALSE we show an warning
    # that this will be ignored
    if (!cacheOK) {
        warning("cacheOK is FALSE, this will be ignored since its not supported in xeus-r-lite", call. = FALSE)
    }

    ret <- hera_dot_call( "xeus_download_file", url, destfile, method, quiet, mode, TRUE, extra, headers)
    # when ret is not NULL, it is an error message
    if (!is.null(ret) && ret != "") {
    
        error_msg <- paste(
            "Download failed, possible reasons:",
            " - Missing CORS Headers",
            " - Network Errors",
            " - URL not found",
            " - File not found",
            "",
            "An informative error message might be accessible via the developer console.",
            "",
            "Traceback:",
            "",
            ret,
            sep = "\n"
        )

        stop(error_msg)
    }
}
xeus_url <- function(description, open = "", blocking=TRUE, encoding = getOption("encoding"), method = getOption("url.method", "auto"), headers = NULL) {

    # warn when blocking is FALSE
    if (!blocking) {
        warning("blocking=FALSE is ignored as this is not implemented in xeus-r-lite", call. = FALSE)
    }
    # warn if encoding != "native.enc"
    if (encoding != "native.enc") {
        warning("Non-native encoding may give unexpected results in xeus-r-lite", call. = FALSE)
    }

    # warn if method is anything but "internal" or "auto" or "default"
    if (method != "internal" && method != "auto" && method != "default") {
        warning(gettextf("download.file method '%s' is not supported in xeus-r-lite, trying to continue with internal method", method), call. = FALSE)
    }

    # try to extract file extension from URL
    ext <- tools::file_ext(description)
    if (nchar(ext) == 0) ext <- "tmp"
    
    # create temp file with appropriate extension
    tmp <- tempfile(fileext = paste0(".", ext))

    
    # download content into temp file
    download.file(description, tmp, quiet = TRUE, mode='wb', headers = headers)

    # open the connection
    con <- file(tmp, open = open)

    # create a small environment to hold the temp file path
    e <- new.env()
    e$tmpfile <- tmp

    # attach finalizer to environment, not to the connection
    reg.finalizer(e, function(env) {
        try(unlink(env$tmpfile), silent = TRUE)
    }, onexit = TRUE)

    # attach environment to connection so it is kept alive
    attr(con, "tempfile_env") <- e

    con
}
xeus_file <- function(description, open = "", blocking = TRUE,
                      encoding = getOption("encoding"), ...) {
  if (grepl("^https?://", description)) {
    # message("Intercepted file() call for URL: ", description)
    tmp <- tempfile(fileext = ".txt")
    download.file(description, tmp, quiet = TRUE)

    con <- original_file(tmp, open = open, blocking = blocking, encoding = encoding, ...)

    # wrap in environment
    wrapper <- new.env(parent = emptyenv())
    wrapper$con <- con
    wrapper$tmp <- tmp


    # attach finalizer to connection object
    reg.finalizer(wrapper, function(e) {
      if (file.exists(tmp)) {
        try(unlink(tmp), silent = TRUE)
      }
    }, onexit = TRUE)

    return(con)

  } else {
    return(original_file(description, open = open,
                      blocking = blocking, encoding = encoding, ...))
  }
}