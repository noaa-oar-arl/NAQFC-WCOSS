
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE plumeRiseSofiev(EMLAYS,TA, PRES, ZH, BFLUX, LPBL, ZPLM)

C-----------------------------------------------------------------------

C Description:  
C     computes final effective plume centerline height, using SOFIEV12

C Preconditions:
C     meteorology and stack parameters

C Subroutines and Functions called:

C Revision History:
C     Ref: M. Sofiev et al., Evaluation of the smoke-injection
C          height from wild-land fires using remote sensing data.
C          Atmos. Chem. Phys., 12, 1995-2006, 2012.
C     Oct 2019, Prototype (Daniel Tong)
C     June 2020, Yunyao Li: Revised to allow below/above PBLH parameterization.

C-----------------------------------------------------------------------
      IMPLICIT NONE
C Arguments:
      INTEGER, INTENT( IN )  :: EMLAYS          ! no. emissions layers
      REAL,    INTENT( IN )  :: TA  ( : )       ! absolute temperature
      REAL,    INTENT( IN )  :: PRES( : )       ! pressure [Pa]
      REAL,    INTENT( IN )  :: ZH  ( : )       ! layer center  height [m]
      REAL,    INTENT( IN )  :: BFLUX           ! FRP (W)
      INTEGER, INTENT( IN )  :: LPBL            ! first L: ZF(L) above mixing layer
      REAL,    INTENT( OUT )  :: ZPLM           ! initially, plume top height above fire,

C Local Variables:
      real pblh         ! PBL height (m)
      real NFT          ! N in Free Troposphere (@ p = 500 hPa)
      real T1, T2       ! Temperature right below and above 500 hPa
      real P1, P2       ! Pressure right below and above 500 hPa
      real PT1, PT2     ! Potential Temperature right below and above 500 hPa
      real laydepth     ! depth of the layer at 500 hPa
      real grav         ! gravity
      real FRP          ! FRP (W)

      real Pf0          ! reference fire power (W)
      real N0           ! Brunt-Vaisala frequency (s-2)
      real alpha        ! part of ABL passed freely
      real beta         ! weights contribution of fire intensity
      real gama         ! power-law dependence on FRP
      real delta        ! dependence on stability in the FT
      
      integer L500      ! L just below 500 hPa
      integer L
C ... predefined values
      alpha     = 0.15
      beta      = 102.0
      gama      = 0.49
      delta     = 0

      Pf0       = 1000000.0
      N0        = 0.00025
      grav      = 9.8

C ... calculate the free troposphere layer and pblh
      L = 1
      L500 = 0
      DO WHILE (L.LT.EMLAYS)
         IF ((PRES(L)-50000)*(PRES(L)-50000).lt.0) THEN
            L500=L
            L=EMLAYS
         END IF
         L=L+1
      END DO
      L500=MAX(1,L500)
      T1=TA(L500)
      T2=TA(L500+1)
      P1=PRES(L500)
      P2=PRES(L500+1)
      laydepth=ZH(L500+1)-ZH(L500) !287.05*(T1+T2)/2.0/9.8*alog(P1/P2)
      pblh = ZH(LPBL)
      FRP=BFLUX

C ... calculate PT from T and P
      PT1 = T1 * (100000/P1)**0.286
      PT2 = T2 * (100000/P2)**0.286

C ... calculate Brunt-Vaisala frequency
      NFT = grav/PT1*abs(PT1-PT2)/laydepth

C ... calculate first guess plume rise top height
      ZPLM = alpha*pblh + beta*(FRP/Pf0)**gama * exp(-delta*NFT/N0)
! ... compare Hp with ABL
      if (ZPLM .lt. pblh) then
        alpha     = 0.24
        beta      = 170
        gama      = 0.35
        delta     = 0.6
        ZPLM = alpha*pblh + beta*(FRP/Pf0)**gama*exp(-delta*NFT/N0)
      else
        alpha     = 0.93
        beta      = 298
        gama      = 0.13
        delta     = 0.7
        ZPLM = alpha*pblh + beta*(FRP/Pf0)**gama*exp(-delta*NFT/N0)
      end if

      END SUBROUTINE plumeRiseSofiev
