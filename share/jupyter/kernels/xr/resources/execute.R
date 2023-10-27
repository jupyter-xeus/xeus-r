last_plot <- NULL

handle_message <- function(msg) {
  publish_stream("stderr", conditionMessage(msg))
}

handle_warning <- function(w) {
  call <- conditionCall(w)
  call <- if (is.null(call)) '' else sprintf(' in %s', deparse(call)[[1]])
  msg <- sprintf('Warning message%s:\n%s\n', call, dQuote(conditionMessage(w)))

  publish_stream("stderr", msg)
}

handle_error <- function(e) {
  sys_calls <- sys.calls()
  stack <- capture.output(traceback(sys_calls, max.lines = 1L))

  evalue <- paste(conditionMessage(e), collapse = "\n")
  trace_back <- c(
    cli::col_red("--- Error"),
    evalue, 
    "",
    cli::col_red("--- Traceback (most recent call last)"), 
    stack
  )
  publish_execution_error(ename = "ERROR", evalue = evalue, trace_back)
}

handle_value <- function(execution_counter) function(obj, visible) {
  set_last_value(obj)
  if (!visible) return()

  # always include text/plain
  mimetypes <- if (getOption('jupyter.rich_display')) {
    c("text/plain", setdiff(getOption("jupyter.display_mimetypes"), "text/plain"))
  } else {
    "text/plain"  
  }
    
  bundle <- IRdisplay::prepare_mimebundle(obj, mimetypes = mimetypes)
  display_data(bundle$data, bundle$metadata)
}

handle_graphics <- function(plot) {
  attr(plot, ".xeusr_width")  <- getOption('repr.plot.width' , repr::repr_option_defaults$repr.plot.width)
  attr(plot, ".xeusr_height") <- getOption('repr.plot.height', repr::repr_option_defaults$repr.plot.height)
  attr(plot, ".xeusr_res")    <- getOption('repr.plot.res', repr::repr_option_defaults$repr.plot.res)
  attr(plot, ".xeusr_ppi")    <- attr(plot, ".xeusr_res") / getOption('jupyter.plot_scale', 2)
  
  if (!plot_builds_upon(last_plot, plot)) {
    send_plot(last_plot)
  }

  last_plot <<- plot
}

send_plot <- function(plot) {
  w <- attr(plot, '.xeusr_width')
  h <- attr(plot, '.xeusr_height')
  res <- attr(plot, ".xeusr_res")
  ppi <- attr(plot, ".xeusr_ppi")

  data <- namedlist()
  metadata <- namedlist()

  for (mime in getOption('jupyter.plot_mimetypes')) {
    data[[mime]] <- repr::mime2repr[[mime]](plot, width = w, height = h, res = res)

    if (!identical(mime, 'text/plain')) {
      metadata[[mime]] <- list(
          width  = w * ppi,
          height = h * ppi
      )
    }

    # Isolating SVGs (putting them in an iframe) avoids strange
    # interactions with CSS on the page.
    if (identical(mime, 'image/svg+xml')) {
      metadata[[mime]]$isolated <- TRUE
    }

  }
  display_data(data, metadata)
}

execute <- function(code, execution_counter) {
  parsed <- tryCatch(
    parse(text = code, srcfile = glue::glue("[{execution_counter}]")), 
    error = function(e) {
      msg <- paste(conditionMessage(e), collapse = "\n")
      publish_execution_error("PARSE ERROR", msg)
      e
    }
  )
  if (inherits(parsed, "error")) return()

  output_handler <- evaluate::new_output_handler(
    text = function(txt) publish_stream("stdout", txt), 
    graphics = handle_graphics,
    message = handle_message, 
    warning = handle_warning, 
    error = handle_error, 
    value = handle_value(execution_counter)
  )

  last_plot <<- NULL

  evaluate::evaluate(
    code,
    envir = globalenv(),
    output_handler = output_handler,
    stop_on_error = 1L
  )

  if (!is.null(last_plot)) {
    tryCatch(send_plot(last_plot), error = handle_error)
  }

}
