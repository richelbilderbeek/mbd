% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mbd_condprob.R
\name{condprob_parmsvec}
\alias{condprob_parmsvec}
\title{Creates vector of parameters for the FORTRAN condprob code}
\usage{
condprob_parmsvec(pars, log_nu_mat, log_q_mat, lx, fortran = TRUE)
}
\arguments{
\item{pars}{vector of parameters:
\itemize{
  \item pars[1] is lambda, the sympatric speciation rate;
  \item pars[2] is mu, the extinction rate;
  \item pars[3] is nu, the multiple allopatric speciation trigger rate;
  \item pars[4] is q, the single-lineage speciation probability;
}}

\item{log_nu_mat}{logarithmic nu-matrix, used for condprob}

\item{log_q_mat}{logarithmic q-matrix, used for condprob}

\item{lx}{it is the number of ODEs considered for the computation.}

\item{fortran}{Set it to TRUE if you want to use FORTRAN routine.}
}
\value{
a vector composed of (in order): lambda, mu, nu, components of the
 nu-q matrix, components of the matrix of columns (m1_mat), components of the
 matrix of rows (m2_mat), components of the empty framed matrix (empty_mat).
}
\description{
Creates vector of parameters for the FORTRAN condprob code
}
\author{
Giovanni Laudanno
}
