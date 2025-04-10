#' Options for current jupyter cell
#'
#' @param ... options to set locally to the notebook cell. Forwarded to [rlang::local_options()].
#'
#' @examples
#' \dontrun{
#'   cell_options(repr.plot.bg = "gray")
#' }
#'
#' @export
cell_options <- function(...) {
    rlang::local_options(..., .frame = the$frame_cell_execute)
}
