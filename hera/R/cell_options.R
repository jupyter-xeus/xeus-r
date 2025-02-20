#' Options for current jupyter cell
#'
#' @inheritParams rlang::local_options
#'
#' @export
cell_options <- function(...) {
    rlang::local_options(..., .frame = the$frame_cell_execute)
}
