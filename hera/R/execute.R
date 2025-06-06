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
  if (inherits(e, "rlang_error") && isNamespaceLoaded("rlang")) {
    assign("last_error", e, triple_colon("rlang", "the"))

    the$last_error <- structure(
      list(ename = "ERROR", evalue = "", format(e, backtrace = TRUE)),
      class = "error_reply"
    )
  } else {
    sys_calls <- sys.calls()
    sys_calls <- head(tail(sys_calls, -16), -3)
    stack <- capture.output(traceback(sys_calls, max.lines = 1L))

    evalue <- paste(conditionMessage(e), collapse = "\n")
    trace_back <- c(
      cli::col_red("--- Error"),
      evalue,
      "",
      cli::col_red("--- Traceback (most recent call last)"),
      stack
    )
    the$last_error <- structure(list(ename = "ERROR", evalue = evalue, trace_back), class = "error_reply")
  }
}

handle_value <- function(obj, visible) {
  set_last_value(obj, visible)

  if (visible && inherits(obj, "ggplot")) {
    print(obj)
    the$last_visible <- FALSE
  }

}

handle_graphics <- function(plot) {
  attr(plot, ".irkernel_width")  <- getOption('repr.plot.width' , repr::repr_option_defaults$repr.plot.width)
  attr(plot, ".irkernel_height") <- getOption('repr.plot.height', repr::repr_option_defaults$repr.plot.height)
  attr(plot, ".irkernel_res")    <- getOption('repr.plot.res', repr::repr_option_defaults$repr.plot.res)
  attr(plot, ".irkernel_ppi")    <- attr(plot, ".irkernel_res") / getOption('jupyter.plot_scale', 2)

  if (!plot_builds_upon(the$last_plot, plot)) {
    send_plot(the$last_plot)
  }

  the$last_plot <- plot
}

send_plot <- function(plot) {
  w <- attr(plot, '.irkernel_width')
  h <- attr(plot, '.irkernel_height')
  res <- attr(plot, ".irkernel_res")
  ppi <- attr(plot, ".irkernel_ppi")

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

# currently not exported, because it is only meant to be called
# from xeus-r / interpreter::execute_request_impl
execute <- function(code, execution_counter, silent = FALSE, eval_env = rlang::global_env()) {
  the$last_error <- NULL

  parsed <- tryCatch(
    parse(text = code),
    error = function(e) {
      msg <- paste(conditionMessage(e), collapse = "\n")
      the$last_error <- structure(list(ename = "PARSE ERROR", evalue = msg), class = "error_reply")
    }
  )
  if (!is.null(the$last_error)) return(the$last_error)

  output_handler <- if (silent) {
    evaluate::new_output_handler()
  } else {
    evaluate::new_output_handler(
      text = function(txt) publish_stream("stdout", txt),
      graphics = handle_graphics,
      message = handle_message,
      warning = handle_warning,
      error = handle_error,
      value = handle_value
    )
  }

  the$last_plot <- NULL
  the$last_visible <- FALSE

  filename <- glue("[{execution_counter}]")

  the$frame_cell_execute <- environment()
  evaluate::evaluate(
    code,
    envir = eval_env,
    output_handler = output_handler,
    stop_on_error = 1L,
    filename = filename
  )
  if (!is.null(the$last_error)) return(the$last_error)

  if (!silent && !is.null(the$last_plot)) {
    tryCatch(send_plot(the$last_plot), error = handle_error)
  }
  if (!is.null(the$last_error)) return(the$last_error)

  if (isTRUE(the$last_visible)) {
    obj <- .Last.value

    bundle <- mime_bundle(obj)

    structure(class = "execution_result",
      list(
        data     = toJSON(bundle$data),
        metadata = toJSON(bundle$metadata)
      )
    )
  }

}
