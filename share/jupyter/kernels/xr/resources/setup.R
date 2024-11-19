local({

  attach(new.env(), "tools:xeusr", pos = 2L)
  .xeus_env <- as.environment("tools:xeusr")
  assign(".xeus_env", .xeus_env, pos = .xeus_env)
  
  here <- file.path(
    dirname(Sys.which("xr")),
    "..", "share", "jupyter", "kernels", "xr", "resources"
  )

  files <- setdiff(list.files(here, recursive = TRUE), "setup.R")

  for (f in files) {
    sys.source(file.path(here, f), envir = .xeus_env)
  }

})
