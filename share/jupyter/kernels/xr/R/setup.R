local({

  xeus_env <- if ("tools:xeusr" %in% search()) {
    asEnvironment("tools:xeusr")
  } else {
    attach(new.env(), "tools:xeusr", pos = 2L)
  }

  here <- file.path(
    dirname(Sys.which("xr")),
    "..", "share", "jupyter", "kernels", "xr", "R"
  )

  xeus_source <- function(...) {
    sys.source(file.path(here, ...), envir = xeus_env)
  }

  xeus_source("hello.R")

})
