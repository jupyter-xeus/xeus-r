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

  files <- setdiff(list.files(here), "setup.R")

  for (f in files) {
    sys.source(file.path(here, f), envir = xeus_env)
  }

})
