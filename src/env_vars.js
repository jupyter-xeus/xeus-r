Module["onRuntimeInitialized"] = () => {
    console.log("R is ready");
}

Module["preRun"] = () => {
    ENV["R_HOME"] = "/lib/R";
    ENV["R_INSTALL_LIBRARY"] = "/lib/R/library/";
    ENV["R_ENVIRON"] = "/lib/R/etc/Renviron";
    ENV["EDITOR"] = "vim";
    ENV["R_ENABLE_JIT"] = "0";
};