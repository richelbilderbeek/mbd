% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mbd_condprob.R
\name{condprob}
\alias{condprob}
\title{Calculate conditional probability: loglik mode}
\usage{
condprob(brts, fortran = TRUE, lx, eq, parmsvec)
}
\arguments{
\item{brts}{A set of branching times of a phylogeny.}

\item{fortran}{Set it to TRUE if you want to use FORTRAN routine.}

\item{lx}{it is the number of ODEs considered for the computation.}

\item{eq}{the equation approach you want to use. It can be "q_eq" for the
Q-equation of "p_eq" for the P-equation.}

\item{parmsvec}{parameters to pass to the FORTRAN scripts}
}
\description{
Calculate conditional probability: loglik mode
}
\author{
Giovanni Laudanno
}
