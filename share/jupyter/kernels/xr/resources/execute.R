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
  if (!visible) return()

  # only doing text-plain for now
  data <- list(
    "text/plain" = capture.output(print(obj))
  )
  
  publish_execution_result(execution_counter, data)
}

handle_graphics <- function(plot) {
  attr(plot, ".xeusr_width")  <- getOption('repr.plot.width' , repr::repr_option_defaults$repr.plot.width)
  attr(plot, ".xeusr_height") <- getOption('repr.plot.height', repr::repr_option_defaults$repr.plot.height)
  attr(plot, ".xeusr_res")    <- getOption('repr.plot.res', repr::repr_option_defaults$repr.plot.res)
  
  if (!plot_builds_upon(last_plot, plot)) {
    send_plot(last_plot)
  }

  last_plot <<- plot
}

send_plot <- function(plot) {
  # TODO: handle more mime types, e.g. IRkernel uses the jupyter.plot_mimetypes option
  w <- attr(plot, '.xeusr_width')
  h <- attr(plot, '.xeusr_height')
  res <- attr(plot, ".xeusr_res")
        
  metadata <- list(
    'image/png' = list(
      width  = w * res, 
      height = h * res
    )
  )
  
  formats <- list(
    'image/png' = repr::mime2repr[['image/png']](plot, width = w, height = h, res = res)
  )
  
  display_data(formats, metadata)
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
    send_plot(last_plot)
  }

}
