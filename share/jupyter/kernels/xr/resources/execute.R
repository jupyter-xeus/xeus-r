last_plot <- NULL
last_visible <- TRUE
last_error <- NULL

handle_message <- function(msg) {
  publish_stream("stderr", conditionMessage(msg))
}

handle_warning <- function(w) {
  call <- conditionCall(w)
  call <- if (is.null(call)) '' else sprintf(' in %s', deparse(call)[[1]])
  msg <- sprintf('Warning message%s:\n%s\n', call, dQuote(conditionMessage(w)))

  publish_stream("stderr", msg)
}

trim_rlang_error <- function(e) {
  trace <- e$trace
  if (is.null(trace) && !is.null(e$parent)) {
    trace <- e$parent$trace
  }
  if (is.null(trace)) return(e)

  # remove the first node - i.e. the .xeus_call() > ...
  trace <- trace[seq(which(trace$parent == 0)[2], nrow(trace)), ]
  # trace <- trace[trace$visible, ]

  # adjust the parent column
  n <- nrow(trace)
  parent <- trace$parent
  root <- 0
  node <- 0
  for (i in 1:n) {
    if (parent[i] == 0) {
      root <- i
      node <- root
    } else {
      parent[i] <- node
      node <- node + 1
    }
  }
  trace$parent <- parent
  e$trace <- trace
  e
}

handle_error <- function(e) {
  if (inherits(e, "rlang_error") && isNamespaceLoaded("rlang")) {
    e <- trim_rlang_error(e)
    assign("last_error", e, rlang:::the)

    trace_back <- c(
      cli::col_red("--- Error"),
      format(e, backtrace = FALSE), 
      "",
      cli::col_red("--- Traceback"), 
      format(e$trace)
    )
    last_error <<- structure(list(ename = "ERROR", evalue = "", trace_back), class = "error_reply")
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
    last_error <<- structure(list(ename = "ERROR", evalue = evalue, trace_back), class = "error_reply")
  }
}

handle_value <- function(obj, visible) {
  set_last_value(obj, visible)

  if (visible && inherits(obj, "ggplot")) {
    print(obj)
    last_visible <<- FALSE
  }

}

handle_graphics <- function(plot) {
  attr(plot, ".irkernel_width")  <- getOption('repr.plot.width' , repr::repr_option_defaults$repr.plot.width)
  attr(plot, ".irkernel_height") <- getOption('repr.plot.height', repr::repr_option_defaults$repr.plot.height)
  attr(plot, ".irkernel_res")    <- getOption('repr.plot.res', repr::repr_option_defaults$repr.plot.res)
  attr(plot, ".irkernel_ppi")    <- attr(plot, ".irkernel_res") / getOption('jupyter.plot_scale', 2)
  
  if (!plot_builds_upon(last_plot, plot)) {
    send_plot(last_plot)
  }

  last_plot <<- plot
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

execute <- function(code, execution_counter, silent = FALSE) {
  last_error <<- NULL
  
  parsed <- tryCatch(
    parse(text = code), 
    error = function(e) {
      msg <- paste(conditionMessage(e), collapse = "\n")
      last_error <<- structure(list(ename = "PARSE ERROR", evalue = msg), class = "error_reply")
    }
  )
  if (!is.null(last_error)) return(last_error)
  
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
  
  last_plot <<- NULL
  last_visible <<- FALSE

  filename <- glue::glue("[{execution_counter}]")

  frame_cell_execute <<- environment()
  evaluate::evaluate(
    code,
    envir = globalenv(),
    output_handler = output_handler,
    stop_on_error = 1L, 
    filename = filename
  )
  if (!is.null(last_error)) return(last_error)

  if (!silent && !is.null(last_plot)) {
    tryCatch(send_plot(last_plot), error = handle_error)
  }
  if (!is.null(last_error)) return(last_error)

  if (isTRUE(last_visible)) {
    obj <- .Last.value

    # TODO: This probably needs to be generalized
    mimetypes <- if (inherits(obj, c("htmlwidget", "shiny.tag.list", "shiny.tag"))) {
      c("text/plain", "text/html")
    } else {
      "text/plain"
    }
    
    bundle <- IRdisplay::prepare_mimebundle(obj, mimetypes = mimetypes)
    
    structure(class = "execution_result", 
      list(toJSON(bundle$data), toJSON(bundle$metadata))
    )
  }

}
