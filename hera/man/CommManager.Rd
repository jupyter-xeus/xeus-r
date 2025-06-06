% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/comm.R
\docType{data}
\name{CommManagerClass}
\alias{CommManagerClass}
\alias{CommManager}
\title{Comm Manager class}
\format{
An object of class \code{CommManagerClass} (inherits from \code{R6}) of length 11.
}
\usage{
CommManager
}
\description{
Instance of the \link{CommManagerClass} class.
}
\keyword{datasets}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-CommManagerClass-new}{\code{CommManagerClass$new()}}
\item \href{#method-CommManagerClass-register_comm_target}{\code{CommManagerClass$register_comm_target()}}
\item \href{#method-CommManagerClass-unregister_comm_target}{\code{CommManagerClass$unregister_comm_target()}}
\item \href{#method-CommManagerClass-new_comm}{\code{CommManagerClass$new_comm()}}
\item \href{#method-CommManagerClass-comms}{\code{CommManagerClass$comms()}}
\item \href{#method-CommManagerClass-target_callback}{\code{CommManagerClass$target_callback()}}
\item \href{#method-CommManagerClass-preserve}{\code{CommManagerClass$preserve()}}
\item \href{#method-CommManagerClass-release}{\code{CommManagerClass$release()}}
\item \href{#method-CommManagerClass-get_comm_info}{\code{CommManagerClass$get_comm_info()}}
\item \href{#method-CommManagerClass-clone}{\code{CommManagerClass$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-new"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-new}{}}}
\subsection{Method \code{new()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$new(..., error_call = caller_env())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{currently unused}

\item{\code{error_call}}{see \code{\link[rlang:args_error_context]{rlang::args_error_context()}}}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-register_comm_target"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-register_comm_target}{}}}
\subsection{Method \code{register_comm_target()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$register_comm_target(
  target_name,
  callback = function(comm, message) {
 }
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{target_name}}{name of the comm target, e.g. "jupyter.widgets"}

\item{\code{callback}}{callback function taking two arguments 'comm' and 'message'.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-unregister_comm_target"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-unregister_comm_target}{}}}
\subsection{Method \code{unregister_comm_target()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$unregister_comm_target(target_name)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{target_name}}{name of the comm target}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-new_comm"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-new_comm}{}}}
\subsection{Method \code{new_comm()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$new_comm(target_name, description = "")}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{target_name}}{name of the target}

\item{\code{description}}{description of the comm}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-comms"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-comms}{}}}
\subsection{Method \code{comms()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$comms()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
the list of currently open comms
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-target_callback"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-target_callback}{}}}
\subsection{Method \code{target_callback()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$target_callback(target_name)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{target_name}}{name of the comm target}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
the callback for that target name
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-preserve"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-preserve}{}}}
\subsection{Method \code{preserve()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$preserve(comm)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{comm}}{\link{Comm} instance to preserve}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-release"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-release}{}}}
\subsection{Method \code{release()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$release(comm)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{comm}}{\link{Comm} instance to release}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-get_comm_info"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-get_comm_info}{}}}
\subsection{Method \code{get_comm_info()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$get_comm_info(target_name = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{target_name}}{name of the target to get info about all comm opens. If NULL, info for comms for all targets are returned.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CommManagerClass-clone"></a>}}
\if{latex}{\out{\hypertarget{method-CommManagerClass-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CommManagerClass$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
