MODULE diffev_random
!
!  Handles logging of the random number status 
!
!  The status of the random number generator at the start of the 
!  currently best individuum is preserved.
!
IMPLICIT NONE
!
CHARACTER(LEN=100) :: random_macro
CHARACTER(LEN=100) :: random_prog
LOGICAL :: write_random_state = .FALSE.
LOGICAL :: l_get_random_state = .TRUE.
!INTEGER, DIMENSION(:,:), ALLOCATABLE :: random_state  ! Status for current members
INTEGER, DIMENSION(5  )              :: random_best   ! Status for best    member
!
CONTAINS
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_on
!
IMPLICIT NONE
!
l_get_random_state = .TRUE.
!
END SUBROUTINE diffev_random_on
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_off
!
IMPLICIT NONE
!
l_get_random_state = .FALSE.
!
END SUBROUTINE diffev_random_off
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
LOGICAL FUNCTION diffev_random_status()
!
IMPLICIT NONE
!
diffev_random_status = l_get_random_state
!
END FUNCTION diffev_random_status
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_write_on(prog, prog_l, macro, macro_l)
!
IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(IN) :: prog
CHARACTER(LEN=*), INTENT(IN) :: macro
INTEGER         , INTENT(IN) :: prog_l
INTEGER         , INTENT(IN) :: macro_l
!
write_random_state = .TRUE.     ! Turn on  documentation
random_prog  = prog(1:prog_l)
random_macro = macro(1:macro_l)
!
END SUBROUTINE diffev_random_write_on
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_write_off
!
IMPLICIT NONE
!
write_random_state = .FALSE.    ! Turn off documentation
!
END SUBROUTINE diffev_random_write_off
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_save(new)
!
IMPLICIT NONE
!
INTEGER, DIMENSION(5), INTENT(IN) :: new
!
random_best(:) = new(:)
!
END SUBROUTINE diffev_random_save
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_best_macro
!
USE population
USE run_mpi_mod
!
IMPLICIT NONE
!
INTEGER, PARAMETER :: IWR = 88
!
CHARACTER(LEN=40) :: macro_file = 'diffev_best.mac'
INTEGER :: i
!
IF(write_random_state) THEN
   CALL oeffne(IWR, macro_file, 'unknown')
!
   WRITE(IWR,'(a)') random_prog(1:LEN_TRIM(random_prog))
   WRITE(IWR,'(a)') '#@ HEADER'
   WRITE(IWR,'(a)') '#@ NAME         diffev_best.mac'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ KEYWORD      diffev, best member, initialize'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro contains the parameters for the current best'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  member. If run the best member will be recreated.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  As the random state is explicitely contained as well, the'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  best member will be recreated exactly.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro uses the original macro on the run_mpi command'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  line. Make sure to turn on writing of desired output files.'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ PARAMETER    $0, 0'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ USAGE        @diffev_best.mac'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ END'
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a,i12)') 'POP_GENERATION = ',pop_gen
   WRITE(IWR,'(a,i12)') 'POP_MEMBER     = ',pop_n
   WRITE(IWR,'(a,i12)') 'POP_CHILDREN   = ',pop_c
   WRITE(IWR,'(a,i12)') 'POP_DIMENSION  = ',pop_dimx
   WRITE(IWR,'(a,i12)') 'POP_KID        = ',9999
   WRITE(IWR,'(a,i12)') 'POP_INDIV      = ',9999
   DO i=1,pop_dimx
      WRITE(IWR,'(A,I12,A,E17.10)') 'ref_para[',i,'] = ',child(i,pop_best)
   ENDDO
   IF(random_best(1) <= 0) THEN
      WRITE(IWR,'(a,i12)') 'seed ',random_best(1)
   ELSE
      WRITE(IWR,'(4(a,i12))') 'seed ',random_best(3), ', ',random_best(4), ', ',random_best(5)
   ENDIF
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a1,a)') '@',random_macro(1:LEN_TRIM(random_macro))
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a)') 'exit'
!
   CLOSE(IWR)
!
ENDIF
!
CALL diffev_random_write_off    ! Turn off documentation
!
END SUBROUTINE diffev_best_macro
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
END MODULE diffev_random