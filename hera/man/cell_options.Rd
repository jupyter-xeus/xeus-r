% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cell_options.R
\name{cell_options}
\alias{cell_options}
\title{Options for current jupyter cell}
\usage{
cell_options(...)
}
\arguments{
\item{...}{options to set locally to the notebook cell. Forwarded to \code{\link[rlang:local_options]{rlang::local_options()}}.}
}
\description{
Options for current jupyter cell
}
\examples{
\dontrun{
  cell_options(repr.plot.bg = "gray")
}

}
