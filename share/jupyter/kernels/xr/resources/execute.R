publish_stream <- function(name, text) {
  invisible(.Call("xeusr_publish_stream", name, text, PACKAGE = "(embedding)"))
}

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
    "Traceback (most recent call last)", 
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

handle_graphics <- function(plotobj) {
  
}

publish_execution_error <- function(ename, evalue, trace_back) {
  invisible(.Call("xeusr_publish_execution_error", ename, evalue, trace_back))
}

publish_execution_result <- function(execution_count, data, metadata = NULL) {
  invisible(.Call("xeusr_publish_execution_result", as.integer(execution_count), jsonlite::toJSON(data), jsonlite::toJSON(metadata)))
}

try_catch <- function(expr) {
  .xeus_sys_calls <- NULL; 
  tryCatch(
    withCallingHandlers(
      withVisible(eval(expr, globalenv())),
      error = function(condition){
        sys_calls <- sys.calls()
        sys_calls <- sys_calls[seq(10, length(sys_calls))]
        .xeus_sys_calls <<- sys_calls
      }
    ), 
    error = function(condition) { 
      structure(list(
        condition = condition, 
        calls = .xeus_sys_calls, 
        stack = capture.output(traceback(.xeus_sys_calls, max.lines = 1L))
      ), class = 'xeus_error')
    }
  )
}

execute <- function(code, execution_counter) {
  output_handler <- evaluate::new_output_handler(
    text = function(txt) publish_stream("stdout", txt), 
    graphics = handle_graphics,
    message = handle_message, 
    warning = handle_warning, 
    error = handle_error, 
    value = handle_value(execution_counter)
  )

  evaluate::evaluate(
    code,
    envir = globalenv(),
    output_handler = output_handler,
    stop_on_error = 1L
  )

}
