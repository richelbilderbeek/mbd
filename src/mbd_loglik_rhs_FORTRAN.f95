! Helper function:
! fill vec with N elements from parms, starting at position ii
!==========================================================================

      SUBROUTINE mbd_fill1d (vec, DIMP, parms, II)
      IMPLICIT NONE
      INTEGER DIMP, II, I
      DOUBLE PRECISION vec(DIMP), parms(*)
      II = II
        DO I = 1, DIMP
          II = II + 1
          vec(I) = parms(II)
        ENDDO

      END SUBROUTINE mbd_fill1d

!==========================================================================
! module with declarations
!==========================================================================

      MODULE mbd_dimmod

      ! length of the vector -  decided in R-code
      INTEGER  :: N

      ! 1 parameter vectors with unknown length
      DOUBLE PRECISION, ALLOCATABLE  :: P(:)

      ! Boolean: will become TRUE if the parameters have a value
      LOGICAL :: initialised = .FALSE.

      END MODULE mbd_dimmod

!==========================================================================
!==========================================================================
! Initialisation: name of this function as passed by "initfunc" argument
! Sets the fixed parameter vector, and allocates memory
!==========================================================================
!==========================================================================

      SUBROUTINE mbd_initmod (steadyparms)
      USE mbd_dimmod

      IMPLICIT NONE
      EXTERNAL steadyparms

      INTEGER, PARAMETER :: nparsmall = 1  ! constant-length parameters

      DOUBLE PRECISION parms(nparsmall)
      COMMON /XCBPar/parms                 ! common block

! Set the fixed parameters obtained from R
      CALL steadyparms(nparsmall, parms)

! first parameter has the length of the vector
      N = INT(parms(1) + 1e-6)

! Allocate variable size arrays (state variables, derivatives and parameters)

      IF (ALLOCATED(P)) DEALLOCATE(P)
      ALLOCATE(P(N ** 2))

      initialised = .FALSE.

      END SUBROUTINE mbd_initmod

!==========================================================================
!==========================================================================
! Initialisation: name of this function as passed by "initfunc" argument
! Sets the fixed parameter vector, and allocates memory
!==========================================================================
!==========================================================================

      SUBROUTINE mbd_initmodpc (steadyparms)
      USE mbd_dimmod

      IMPLICIT NONE
      EXTERNAL steadyparms

      INTEGER, PARAMETER :: nparsmall = 1  ! constant-length parameters

      DOUBLE PRECISION parms(nparsmall)
      COMMON /XCBPar/parms                 ! common block

! Set the fixed parameters obtained from R
      CALL steadyparms(nparsmall, parms)

! first parameter has the length of the vector
      N = INT(sqrt(parms(1) + 1e-6))

! Allocate variable size arrays (state variables, derivatives and parameters)

      IF (ALLOCATED(P)) DEALLOCATE(P)
      ALLOCATE(P(3 + N ** 2))

      initialised = .FALSE.

      END SUBROUTINE mbd_initmodpc



!==========================================================================
!==========================================================================
! Dynamic routine: name of this function as passed by "func" argument
! variable parameter values are passed via yout
!==========================================================================
!==========================================================================

      SUBROUTINE mbd_runmod (neq, t, Conc, dConc, yout, ip)
      USE mbd_dimmod
      IMPLICIT NONE

!......................... declaration section.............................
      INTEGER           :: neq, ip(*), i, ii
      DOUBLE PRECISION  :: t, Conc(N), dConc(N), yout(*)
      REAL(16)          :: V(N)

! parameters - named here
      DOUBLE PRECISION rn
      COMMON /XCBPar/rn

! local variables
      CHARACTER(len=100) msg

!............................ statements ..................................

      IF (.NOT. Initialised) THEN
        ! check memory allocated to output variables
        IF (ip(1) < 1) CALL rexit("nout not large enough")

        ! save parameter values in yout
        ii = ip(1)   ! Start of parameter values
        CALL mbd_fill1d(P, N ** 2, yout, ii)   ! ii is updated in fill1d
        Initialised = .TRUE.          ! to prevent from initialising more than once
      ENDIF

! dynamics

!mbd_loglik_rhs <- function(t, x, params) {
!  list(params %*% x)
!}

      DO I = 1, N
        V(I) = 0
        DO II = 1, N
          V(I) = V(I) + P((II - 1) * N + I) * Conc(II)
        ENDDO
        dConc(I) = V(I)
      ENDDO

      END SUBROUTINE mbd_runmod


!==========================================================================
!==========================================================================
! Dynamic routine: name of this function as passed by "func" argument
! variable parameter values are passed via yout
!==========================================================================
!==========================================================================

      SUBROUTINE mbd_runmodpc (neq, t, Conc, dConc, yout, ip)
      USE mbd_dimmod
      IMPLICIT NONE

!......................... declaration section.............................
      INTEGER           :: neq, ip(*), i, ii, lx, I1, J1, n1
      DOUBLE PRECISION  :: t, Conc(N ** 2), dConc(N ** 2), yout(*)
      DOUBLE PRECISION  :: la, mu, nu
      DOUBLE PRECISION  :: nu_q_mat(N, N), dp1(N, N), dp2(N, N), dp3(N, N)
      DOUBLE PRECISION  :: Conc2(N + 2, N + 2)
      REAL(16)          :: aux1(N,N), aux2(N,N)

! parameters - named here
      DOUBLE PRECISION rn
      COMMON /XCBPar/rn

! local variables
      CHARACTER(len=100) msg

!............................ statements ..................................

      IF (.NOT. Initialised) THEN
        ! check memory allocated to output variables
        IF (ip(1) < 1) CALL rexit("nout not large enough")

        ! save parameter values in yout
        ii = ip(1)   ! Start of parameter values
        CALL mbd_fill1d(P, 3 + N ** 2, yout, ii)   ! ii is updated in fill1d
        Initialised = .TRUE.          ! to prevent from initialising more than once
      ENDIF

! dynamics
!  lx2 <- length(pvec)
!  lx <- sqrt(lx2)
!  pp <- matrix(pvec, lx, lx)
!  mm <- 2:(lx + 1)
!  lambda <- parmsvec[1]
!  mu <- parmsvec[2]
!  nu <- parmsvec[3]
!  nu_q_mat <- parmsvec[(3 + 1):(3 + lx2)]
!  dim(nu_q_mat) <- c(lx, lx)
!  pp2 <- matrix(0, lx + 2, lx + 2)
!  pp2[mm, mm] <- pp

      DO I = 1, (N + 1)
        Conc2(I,1) = 0
        Conc2(I,N + 2) = 0
        Conc2(1,N - I) = 0
        Conc2(N + 2,N - I) = 0
      ENDDO

      DO I = 1, N
        DO II = 1, N
           nu_q_mat(I,II) = P(3 + (II - 1) * N + I)
           Conc2(I + 1,II + 1) = Conc((II - 1) * N + I)
        ENDDO
      ENDDO

!  mvec <- 1:lx - 1
!  dp_lambda <- matrix(0, lx, lx)
!  for (mm2 in mvec) {
!    for (mm1 in mvec) {
!      i <- mm2 + 1
!      j <- mm1 + 1
!      dp_lambda[i, j] <-
!        (mm1 - 1) * pp2[i + 1, j] +
!        (mm2 - 1) * pp2[i, j + 1] -
!        (mm1 + mm2) * pp2[i + 1, j + 1]
!    }
!  }
!  dp_mu <- matrix(0, lx, lx)
!  for (mm2 in mvec) {
!    for (mm1 in mvec) {
!      i <- mm2 + 1
!      j <- mm1 + 1
!      dp_mu[i, j] <-
!        (mm1 + 1) * pp2[i + 1, j + 2] +
!        (mm2 + 1) * pp2[i + 2, j + 1] -
!        (mm1 + mm2) * pp2[i + 1, j + 1]
!    }
!  }
!  nu_q_mat2 <- t(nu_q_mat)
!  dp_nu <- aux1 <- aux2 <-  matrix(0, lx, lx)
!  for (m1 in 1:lx) {
!    for (n2 in 1:lx) {
!      sum1 <- 0
!      for (n1 in 1:lx) {
!        sum1 <- sum1 + nu_q_mat[m1, n1] * pp[n1, n2]
!      }
!      aux1[m1, n2] <- sum1
!    }
!  }
!  for (m1 in 1:lx) {
!    for (m2 in 1:lx) {
!      sum1 <- 0
!      for (n2 in 1:lx) {
!        sum1 <- sum1 + aux1[m1, n2] * nu_q_mat2[n2, m2]
!      }
!      aux2[m1, m2] <- sum1
!    }
!  }
!  dp_nu <- aux2 - pp
!  dp <- lambda * dp_lambda + mu * dp_mu + nu * dp_nu
!  dim(dp) <- c(lx2, 1)

   DO I = 1, N
     Do II = 1, N
       IF (I < N .AND. II < N) THEN

!      i <- mm2 + 1
!      j <- mm1 + 1

         I1 = I + 1
         J1 = II + 1

!      dp_lambda[i, j] <-
!        (mm1 - 1) * pp2[i + 1, j] +
!        (mm2 - 1) * pp2[i, j + 1] -
!        (mm1 + mm2) * pp2[i + 1, j + 1]

         dp1(I,II) = (II - 1) * Conc2(I1 + 1,J1)
         dp1(I,II) = dp1(I,II) + (I - 1) * Conc2(I1,J1 + 1)
         dp1(I,II) = dp1(I,II) - (I + II) * Conc2(I1 + 1,J1 + 1)

!      dp_mu[i, j] <-
!        (mm1 + 1) * pp2[i + 1, j + 2] +
!        (mm2 + 1) * pp2[i + 2, j + 1] -
!        (mm1 + mm2) * pp2[i + 1, j + 1]

         dp2(I,II) = (II + 1) * Conc2(I1 + 1,J1 + 2)
         dp2(I,II) = dp2(I,II) + (I + 1) * Conc2(I1 + 2,J1 + 1)
         dp2(I,II) = dp2(I,II) - (I + II) * Conc2(I1 + 1,J1 + 1)

       ENDIF

!      sum1 <- 0
!      for (n1 in 1:lx) {
!        sum1 <- sum1 + nu_q_mat[m1, n1] * pp[n1, n2]
!      }
!      aux1[m1, n2] <- sum1

       aux1(I,II) = 0
       DO n1 = 1, N
         aux1(I,II) = aux1(I,II) + nu_q_mat(I,n1) * Conc2(n1,II)
       ENDDO

!      sum1 <- 0
!      for (n2 in 1:lx) {
!        sum1 <- sum1 + aux1[m1, n2] * nu_q_mat2[n2, m2]
!      }
!      aux2[m1, m2] <- sum1

       aux2(I,II) = 0
       DO n1 = 1, N
         aux2(I,II) = aux2(I,II) + aux1(I,n1) * nu_q_mat(II,n1)
       ENDDO

!  dp_nu <- aux2 - pp

       dp3 = aux2(I,II) - Conc2(I,II)

!  dp <- lambda * dp_lambda + mu * dp_mu + nu * dp_nu

       dConc((I - 1)*N + II) = P(1)*dp1(I,II) + P(2)*dp2(I,II) + P(3)*dp3(I,II)

     ENDDO
   ENDDO


   END SUBROUTINE mbd_runmodpc

