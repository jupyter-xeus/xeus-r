local({

  attach(new.env(), "tools:xeusr", pos = 2L)
  .xeus_env <- as.environment("tools:xeusr")
  assign(".xeus_env", .xeus_env, pos = .xeus_env)

  # Sys.which is not available in WebAssembly
  if (grepl("emscripten", R.version$os)) {
    here <- file.path(
      "share", "jupyter", "kernels", "xr", "resources"
    )
  } else {
    here <- file.path(
      dirname(Sys.which("xr")),
      "..", "share", "jupyter", "kernels", "xr", "resources"
    )
  }

  files <- setdiff(list.files(here), "setup.R")

  for (f in files) {
    sys.source(file.path(here, f), envir = .xeus_env)
  }

})
