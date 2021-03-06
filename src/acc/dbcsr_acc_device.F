!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2018  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

MODULE dbcsr_acc_device
#if defined (__DBCSR_ACC)
   USE ISO_C_BINDING, ONLY: C_INT
#endif
#include "base/dbcsr_base_uses.f90"

   IMPLICIT NONE

   PUBLIC :: acc_get_ndevices, acc_set_active_device, acc_clear_errors

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'dbcsr_acc_device'

#if defined (__DBCSR_ACC)
   INTERFACE
      FUNCTION acc_get_ndevices_cu(n_devices) RESULT(istat) &
         BIND(C, name="acc_get_ndevices")
         IMPORT
         INTEGER(KIND=C_INT), INTENT(OUT)         :: n_devices
         INTEGER(KIND=C_INT)                      :: istat

      END FUNCTION acc_get_ndevices_cu

      FUNCTION acc_set_active_device_cu(dev_id) RESULT(istat) &
         BIND(C, name="acc_set_active_device")
         IMPORT
         INTEGER(KIND=C_INT), INTENT(IN), VALUE   :: dev_id
         INTEGER(KIND=C_INT)                      :: istat

      END FUNCTION acc_set_active_device_cu

      SUBROUTINE acc_clear_errors_cu() &
         BIND(C, NAME="acc_clear_errors")
      END SUBROUTINE acc_clear_errors_cu
   END INTERFACE

#endif

CONTAINS

! **************************************************************************************************
!> \brief Get number of accelerator devices
!> \return number of accelerator devices
! **************************************************************************************************
   FUNCTION acc_get_ndevices() RESULT(n)
      INTEGER                                  :: n

#if defined (__DBCSR_ACC)
      INTEGER                                  :: istat
#endif

      n = 0
#if defined (__DBCSR_ACC)
      istat = acc_get_ndevices_cu(n)
      IF (istat /= 0) &
         DBCSR_ABORT("acc_get_ndevices: failed")
#endif
   END FUNCTION acc_get_ndevices

! **************************************************************************************************
!> \brief Set active accelerator device
!> \param dev_id device ID
! **************************************************************************************************
   SUBROUTINE acc_set_active_device(dev_id)
      INTEGER :: dev_id

#if defined (__DBCSR_ACC)
      INTEGER :: istat

!$OMP PARALLEL DEFAULT(NONE) PRIVATE(istat) SHARED(dev_id)
      istat = acc_set_active_device_cu(dev_id)
      IF (istat /= 0) &
         DBCSR_ABORT("acc_set_active_device: failed")
!$OMP END PARALLEL

#else
      MARK_USED(dev_id)
      DBCSR_ABORT("__DBCSR_ACC not compiled in")
#endif
   END SUBROUTINE acc_set_active_device

! **************************************************************************************************
!> \brief Clear CUDA errors
! **************************************************************************************************
   SUBROUTINE acc_clear_errors()
#if defined (__DBCSR_ACC)
      CALL acc_clear_errors_cu()
#else
      DBCSR_ABORT("__DBCSR_ACC not compiled in")
#endif
   END SUBROUTINE acc_clear_errors

END MODULE dbcsr_acc_device
