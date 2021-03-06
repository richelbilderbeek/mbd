context("mbd_ml")

is_on_ci <- function() {
  is_it_on_appveyor <- Sys.getenv("APPVEYOR") != ""
  is_it_on_travis <- Sys.getenv("TRAVIS") != ""
  is_it_on_appveyor || is_it_on_travis # nolint internal function
}

test_that("compare results from bd and mbd in case of nu = q = 0", {

  if (!is_on_ci()) {
    skip("To be performed on ci.")
  }

  brts <- c(10, 7, 6, 4, 2, 1)
  start_pars <- c(0.20, 0.10, 0, 0)
  n_0 <- 2
  cond <- 1
  optim_ids <- c(TRUE, TRUE, FALSE, FALSE)
  verbose <- FALSE
  maxiter <- 300

  mbd_out <- mbd::mbd_ml(
    start_pars = start_pars,
    brts = brts,
    cond = cond,
    n_0 = n_0,
    optim_ids = optim_ids,
    true_pars = start_pars,
    verbose = verbose,
    maxiter = maxiter
  )

  for (var_name in mbd::get_param_names()) { # nolint internal function
    testthat::expect_true(mbd_out[var_name] >= 0)
  }
  testthat::expect_true(mbd_out$q <= 1)
  testthat::expect_true(is.numeric(mbd_out$loglik) == TRUE)
  testthat::expect_true(mbd_out$loglik <= 0)
  testthat::expect_true(mbd_out$df == sum(optim_ids))

  x <- utils::capture.output(bd_out <- DDD::bd_ML(
    brts = brts,
    idparsopt = 1:2,
    initparsopt = start_pars[1:2],
    soc = n_0,
    cond = cond
  ))
  rm(x)
  testthat::expect_equal(
    unname(mbd_out$lambda),
    unname(bd_out$lambda0),
    tolerance = 1e-2
  )
  testthat::expect_equal(
    unname(mbd_out$mu),
    unname(bd_out$mu0),
    tolerance = 1e-2
  )
})

test_that("nu = q = 0 gives error", {

  if (!is_on_ci()) {
    skip("To be performed on ci.")
  }
  # This setting gives a rather unhelpful error:
  #
  # Error: in ‘subplex’: f() values at end points not of opposite sign
  #
  set.seed(44)
  expect_silent(
    mbd_ml(
      brts = c(3.0, 2.0),
      start_pars = c(0.3, 0.1, 0.0, 0.0),
      true_pars = c(0.3, 0.1, 0.0, 0.0),
      optim_ids = c(TRUE, TRUE, FALSE, FALSE),
      cond = 1,
      n_0 = 2,
      verbose = FALSE
    )
  )
})


test_that("mbd_ml can be silent", {

  if (!is_on_ci()) {
    skip("To be performed on ci.")
  }

  brts <- c(10, 6, 3)
  optim_ids <- c(FALSE, TRUE, FALSE, FALSE)
  start_pars <- c(0.2, 0.15, 1, 0.1)
  n_0 <- 2
  cond <- 1
  verbose <- FALSE
  ml_sequence <- 1
  maxiter <- 5
  testthat::expect_silent(
    mbd::mbd_ml(
      start_pars = start_pars,
      optim_ids = optim_ids,
      true_pars = start_pars,
      brts = brts,
      cond = cond,
      n_0 = n_0,
      verbose = verbose,
      maxiter = maxiter,
      ml_sequence = ml_sequence
    )
  )
})

test_that("mbd_ml can produce output", {

  if (!is_on_ci()) {
    skip("To be performed on ci.")
  }

  brts <- c(10, 5, 2)
  optim_ids <- c(FALSE, TRUE, FALSE, FALSE)
  start_pars <- c(0.2, 0.15, 1, 0.1)
  n_0 <- 2
  cond <- 1
  verbose <- TRUE
  maxiter <- 5
  ml_sequence <- 1
  output <- utils::capture.output(
    mbd::mbd_ml(
      start_pars = start_pars,
      true_pars = start_pars,
      optim_ids = optim_ids,
      brts = brts,
      cond = cond,
      n_0 = n_0,
      verbose = verbose,
      maxiter = maxiter,
      ml_sequence = ml_sequence
    )
  )
  testthat::expect_true(
    length(output) > 0
  )
  testthat::expect_false(
    is.null(output)
  )
})

test_that("abuse", {

  brts <- c(10, 9, 7, 6, 5)
  start_pars <- c(0.2, 0.15, 1, 0.1)
  n_0 <- 2
  cond <- 1

  testthat::expect_error(
    mbd::mbd_ml(
      start_pars = c(0.2, 0.15, -1, 0.1),
      brts = brts,
      cond = cond,
      n_0 = n_0,
      verbose = FALSE
    ),
    "You cannot start from negative parameters!"
  )
  testthat::expect_output(
    suppressWarnings(mbd::mbd_ml(
      start_pars = c(60, 50, 100, 0.5),
      brts = brts,
      cond = cond,
      n_0 = n_0,
      verbose = FALSE
    )),
    "The initial parameter values have a likelihood that is equal to 0 or below machine precision. Try again with different initial values." # nolint
  )
  testthat::expect_error(
    test <- mbd::mbd_ml(
      loglik_function = mbd_loglik,
      brts = brts,
      start_pars = c(-1, 0.1, 2, 0.1),
      cond = cond,
      n_0 = 2,
      verbose = FALSE
    ),
    "You cannot start from negative parameters!"
  )

})
