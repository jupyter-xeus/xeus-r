local({

  options("cli.num_colors" = 256L)
  
  # TODO: get inspiration from IRkernel::init_null_device
  options(device = function(filename = NULL, ...) {
    pdf(filename, ...)
  })

  xeus_env <- if ("tools:xeusr" %in% search()) {
    asEnvironment("tools:xeusr")
  } else {
    public_env <- new.env()
    private_env <- new.env(parent = public_env)
    assign(".xeusr_private_env", private_env, envir = public_env)

    attach(public_env, "tools:xeusr", pos = 2L)
  }

  xeus_private_env <- get(".xeusr_private_env", envir = xeus_env)

  here <- file.path(
    dirname(Sys.which("xr")),
    "..", "share", "jupyter", "kernels", "xr", "resources"
  )

  files <- setdiff(list.files(here), "setup.R")

  xeus_env$.xeus_call <- function(fn, ...) {
    get(fn, envir = xeus_private_env)(...)
  }

  for (f in files) {
    sys.source(file.path(here, f), envir = xeus_private_env)
  }

})
