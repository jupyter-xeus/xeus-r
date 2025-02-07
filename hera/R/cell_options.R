cell_options <- function(...) {
    rlang::local_options(..., .frame = the$frame_cell_execute)
}
