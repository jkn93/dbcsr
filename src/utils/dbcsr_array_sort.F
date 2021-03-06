!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2018  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

#:include 'dbcsr_array_sort.fypp'

! **************************************************************************************************
!> \brief Routine for sorting an array
!> \note
!>      CP2K:
!>      Please use the interface definded in util.F for calling sort().
!>
!>      DBCSR:
!>      Please use the interface definded in dbcsr_toollib.F for calling sort().
!> \par History
!>      12.2012 first version [ole]
!> \author Ole Schuett
! **************************************************************************************************
MODULE dbcsr_array_sort

USE dbcsr_kinds, ONLY: ${uselist(usekinds)}$

  IMPLICIT NONE
  PRIVATE

  LOGICAL, PRIVATE, PARAMETER :: debug_this_module=.FALSE.
  CHARACTER(len=*), PRIVATE, PARAMETER :: moduleN='dbcsr_array_sort'

#:for nametype in nametype1
  PUBLIC :: dbcsr_1d_${nametype}$_sort
#:endfor

  CONTAINS

#:for nametype1, type1, lessQ in inst_params
! **************************************************************************************************
!> \brief Sorts an array inplace using a combination of merge- and bubble-sort.
!>        It also returns the indices, which the elements had before the sort.
!> \param arr the array to sort
!> \param n length of array
!> \param indices returns elements-indices before the sort
!> \par History
!>      12.2012 created [ole]
!> \author Ole Schuett
! **************************************************************************************************
subroutine dbcsr_1d_${nametype1}$_sort(arr, n, indices)
   integer, intent(in)                  :: n
   ${type1}$, dimension(1:n), intent(inout) :: arr
   integer, dimension(1:n), intent(out)   :: indices

   integer :: i
   ${type1}$, pointer                   :: tmp_arr(:)
   integer, pointer                   :: tmp_idx(:)

   if(n == 0) return ! for some reason this is a frequent case in cp2k

   ! scratch space used during the merge step
   allocate(tmp_arr((size(arr)+1)/2), tmp_idx((size(arr)+1)/2))

   indices = (/ (i, i = 1, size(arr)) /)

   call dbcsr_1d_${nametype1}$_sort_low(arr(1:n), indices, tmp_arr, tmp_idx)

   deallocate(tmp_arr,tmp_idx)

end subroutine dbcsr_1d_${nametype1}$_sort



! **************************************************************************************************
!> \brief The actual sort routing.
!> 	   Only dbcsr_1d_${nametype1}$_sort and itself should call this.
!> \param arr the array to sort
!> \param indices elements-indices before the sort
!> \param tmp_arr scratch space
!> \param tmp_idx scratch space
!> \par History
!>      12.2012 created [ole]
!> \author Ole Schuett
! **************************************************************************************************
recursive subroutine dbcsr_1d_${nametype1}$_sort_low(arr, indices, tmp_arr, tmp_idx)
   ${type1}$, dimension(:), intent(inout) :: arr
   integer, dimension(size(arr)), intent(inout) :: indices
   ${type1}$, dimension((size(arr)+1)/2), intent(inout) :: tmp_arr
   integer, dimension((size(arr)+1)/2), intent(inout) :: tmp_idx
   ${type1}$ :: a
   integer :: t, m, i,j, k
   LOGICAL :: swapped
   ! a,t:  used during swaping of elements in arr and indices

   swapped=.TRUE.

   ! If only a few elements are left we switch to bubble-sort for efficiency.
   if (size(arr) <= 7) then ! 7 seems to be a good choice for the moment
          DO j = size(arr)-1, 1, -1
            swapped = .FALSE.
            DO i = 1, j
                 IF (@{lessQ(arr(i+1), arr(i))}@) THEN
                	 ! swap arr(i) with arr(i+1)
                        a            = arr(i)
                        arr(i)       = arr(i+1)
                        arr(i+1)     = a
                        ! swap indices(i) with indices(i+1)
                        t            = indices(i)
                        indices(i)   = indices(i+1)
                        indices(i+1) = t
                        swapped      = .true.
                 END IF
            END DO
        IF (.NOT. swapped) EXIT
        END DO
      return
   endif

   ! split list in half and recusively sort both sublists
   m = (size(arr)+1)/2 ! index where we going to divide the list in two
   call dbcsr_1d_${nametype1}$_sort_low(arr(1:m), indices(1:m), tmp_arr, tmp_idx)
   call dbcsr_1d_${nametype1}$_sort_low(arr(m+1:), indices(m+1:), tmp_arr, tmp_idx)

   ! Check for a special case: Can we just concate the two sorted sublists?
   ! This leads to O(n) scaling if the input is already sorted.
   if (@{lessQ(arr(m+1), arr(m))}@) then
      ! ...no - let's merge the two sorted sublists arr(:m) and arr(m+1:)
      ! Merge will be performed directly in arr. Need backup of first sublist.
      tmp_arr(1:m) = arr(1:m)
      tmp_idx(1:m) = indices(1:m)
      i = 1; ! number of elemens consumed from 1st sublist
      j = 1; ! number of elemens consumed from 2nd sublist
      k = 1; ! number of elemens already merged

      do while(i <= m .and. j <= size(arr)-m )
      if (@{lessQ(arr(m+j), tmp_arr(i))}@) then
         arr(k)     = arr(m+j)
         indices(k) = indices(m+j)
         j = j+1
      else
         arr(k)     = tmp_arr(i)
         indices(k) = tmp_idx(i)
         i = i+1
      endif
      k = k + 1
      enddo

      ! One of the two sublist is now empty.
      ! Copy possibly remaining tail of 1st sublist
      do while (i <= m)
         arr(k)     = tmp_arr(i)
         indices(k) = tmp_idx(i)
         i = i + 1
         k = k + 1
         enddo

     ! The possibly remaining tail of 2nd sublist is already at the right spot.

   endif

end subroutine dbcsr_1d_${nametype1}$_sort_low
#:endfor

END MODULE dbcsr_array_sort
