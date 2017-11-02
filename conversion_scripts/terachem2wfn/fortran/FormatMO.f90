! Joint BioEnergy Institute
! Dr. Matthew J L Mills - Rhorix 1.0.0
!
! Program FormatMO exists to format the unformatted MO coefficients written by TeraChem to its output files;
! c0 (for restricted wavefunctions) or cA and cB (for unrestricted wavefunctions)
! Input is provided via the namelist file params.nml; it specifies the input file (c0, cA or cB) and the number of primitive gaussians.
! The former is to keep the program simple, the latter is because I am not sure how to infer the num of primitives from the data size.
! An example input file looks as follows:
!
! &params 
! inputFilename = 'c0', 
! Nprimitives = 1356
! &END
!
! Note: The binary MO coefficient file is written by C, meaning we need ACCESS='stream' from the Fortran2003 spec to read it properly.
! To compile and link the program, enter 'make all' at the command line. Requires gfortran and make. Not tested on any other compiler.

PROGRAM FormatMO

  IMPLICIT NONE

  NAMELIST /params/ inputFilename, Nprimitives
  CHARACTER(100) :: inputFilename
  INTEGER :: Nprimitives

  INTEGER, PARAMETER :: inputUnit = 10, outputUnit = 11, nmlUnit = 12
  INTEGER :: i, j, ios, als
  REAL(8), ALLOCATABLE :: unformattedData(:)

  ! The namelist must be opened and read first

  OPEN(nmlUnit,FILE='params.nml',STATUS='old',IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*,*) "ERROR: Namelist params.nml could not be opened. ERROR CODE: ", ios
    STOP
  ENDIF
  READ(nmlUnit,NML=params,IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*,*) "ERROR: Problem during reading of namelist params.nml. ERROR CODE: ", ios
    STOP
  ENDIF
  CLOSE(nmlUnit)

  ! The MO coefficient file must be opened, memory allocated for the data and the file read.

  OPEN(inputUnit,FILE=TRIM(ADJUSTL(inputFilename)),ACCESS='stream',ACTION='read',FORM='unformatted',STATUS='old',IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*,*) "ERROR: File ", TRIM(ADJUSTL(inputFilename)), " could not be opened. ERROR CODE: ", ios
    STOP
  ENDIF
  ALLOCATE(unformattedData(Nprimitives*Nprimitives), STAT=als)
  IF (als /= 0) THEN
    WRITE(*,*) "ERROR: Allocation of memory failed. ERROR CODE: ", als
    STOP
  ENDIF
  READ(inputUnit,IOSTAT=ios) unformattedData(:)
  IF (ios > 0) THEN
    WRITE(*,*) "ERROR: Problem during reading of input file. ERROR CODE: ", ios
    STOP
  ELSE IF (ios < 0) THEN
    WRITE(*,*) "ERROR: End-of-file during reading of input file. ERROR CODE: ", ios
    STOP
  ENDIF
  CLOSE(inputUnit)

  ! Now the data can be formatted and output simultaneously

  OPEN(outputUnit,FILE=TRIM(ADJUSTL(inputFilename))//'-formatted',ACTION='write',STATUS='replace',IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*,*) "ERROR: Output file could not be opened. ERROR CODE: ", ios
    STOP
  ENDIF
  DO i = 1, Nprimitives !loop over MOs
!    WRITE(outputUnit,'(I8)',ADVANCE='no') i
    DO j = 1, Nprimitives !loop over AO coefficients
      WRITE(outputUnit,'(D16.8)',ADVANCE='no') unformattedData(i+(j-1)*Nprimitives)
    ENDDO
    WRITE(outputUnit,*)
  ENDDO

  ! And finally clean up the remaining file handle and allocated memory

  CLOSE (outputUnit, IOSTAT=ios)
    IF (ios /= 0) THEN
      WRITE(*,*) "ERROR: File could not be closed. ERROR CODE: ", ios
    STOP
  ENDIF

  IF (ALLOCATED(unformattedData)) DEALLOCATE(unformattedData, STAT=als)
  IF (als /= 0) THEN
    WRITE(*,*) "ERROR: Deallocation of memory failed. ERROR CODE: ", als
  ENDIF

END PROGRAM FormatMO
