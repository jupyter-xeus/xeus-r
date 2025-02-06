cell_options <- function(...) {
    rlang::local_options(..., .frame = frame_cell_execute)
}
