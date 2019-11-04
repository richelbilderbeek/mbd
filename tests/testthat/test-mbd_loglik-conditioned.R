context("mbd_loglik-conditioned")

is_on_ci <- function() {
  is_it_on_appveyor <- Sys.getenv("APPVEYOR") != ""
  is_it_on_travis <- Sys.getenv("TRAVIS") != ""
  is_it_on_appveyor || is_it_on_travis # nolint internal function
}

# conditioned likelihood is greater than unconditioned likelihood ----
test_that("conditioned likelihood is greater than unconditioned likelihood", {

  pars <- c(0.2, 0.15, 2.0, 0.1)
  brts <- c(5, 4, 3, 3, 1)
  n_0 <- 2

  testthat::expect_true(
    mbd::mbd_loglik(
      pars = pars,
      brts = brts,
      n_0  = n_0,
      cond = 0
    ) <=
    mbd::mbd_loglik(
      pars = pars,
      brts = brts,
      n_0  = n_0,
      cond = 1
    )
  )
})

# right conditioning ----
test_that("right conditioning", {

  pars <- c(0.2, 0.15, 0, 0.1)
  brts <- c(5, 4, 1)
  n_0  <- 2
  cond <- 1

  pars2 <- c(0, cond, 0, 0, n_0)
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = pars,
      brts = brts,
      n_0 = n_0,
      cond = cond,
      lx = 100 + is_on_ci() * 200
    ),
    DDD::bd_loglik(
      pars1 = pars[1:3],
      pars2 = pars2,
      brts = brts,
      missnumspec = 0
    ),
    tolerance = 1e-2 * (!is_on_ci()) + 1e-5 * (is_on_ci())
  )
})

# abuse ----
test_that("abuse", {

  testthat::expect_error(
    mbd::mbd_loglik(
      pars = c(0.1), # Too few
      brts = c(1, 2, 3),
      n_0 = 2, # Crown age
      cond = 1  # Non extinction of the phylogeny
    ),
    "'pars' must have a length of four"
  )

  testthat::expect_error(
    mbd::mbd_loglik(
      pars = c(NaN, 0.15, 2.0, 0.1),
      brts = c(1, 2, 3),
      n_0 = 2, # Crown age
      cond = 1  # Non extinction of the phylogeny
    ),
    "'pars' cannot contain NaNs"
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(Inf, 0.15, 2.0, 0.1),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(-12.34, 0.15, 2.0, 0.1),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(0.2, -12.34, 2.0, 0.1),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(0.2, 0.15, -12.34, 0.1),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(0.2, 0.15, 2.0, -12.34),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
  testthat::expect_equal(
    mbd::mbd_loglik(
      pars = c(0.2, 0.15, 2.0, 12.34),
      brts = c(1, 2, 3),
      n_0 = 2,
      cond = 1
    ),
    -Inf
  )
})