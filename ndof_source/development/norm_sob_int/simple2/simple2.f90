PROGRAM int_test
  USE sobol
  IMPLICIT NONE

  INTEGER :: d, Nsobol
  INTEGER :: n, i, j, k, m, o, p
  INTEGER, PARAMETER :: deg = 6       !polynomial we want to calculate up to
  INTEGER*8 :: skip
  DOUBLE PRECISION, ALLOCATABLE:: norm(:,:)
  DOUBLE PRECISION, DIMENSION(1:10) :: herm, coef
  DOUBLE PRECISION, DIMENSION(1:10, 1:10) :: A

  d = 1                           
  Nsobol = 100000
  skip = 1000

  ALLOCATE (norm(d,Nsobol))

OPEN(UNIT=10, FILE='data.dat')
A=0d0
!=========================Get each sobol pointpoint=========================!
  DO n = 1, Nsobol                
    CALL sobol_stdnormal(d,skip,norm(:,n))
  END DO
  norm=norm/SQRT(2.)      
!=========================Get each sobol pointpoint=========================!

!=========================Get each wavefn coef.=========================!
  coef(1) = 1
  coef(2) = 1.0 / (SQRT(2.0))
  DO p = 3,deg
    coef(p) = coef(p-1)*(1 /SQRT(2.0*REAL(p-1)))
  END DO
 

!=========================Get each wavefn coef.=========================!


!=========================evaluate each sobol point=========================!
  DO i = 1, Nsobol              
        herm(1) = 1.0             
        herm(2) = 2.0*norm(1,i)       
        
      !======================evaluate each herm for a single sobol point=========================!
        DO j = 3,deg      
             herm(j) =(2.0*norm(d,i)*herm(j-1)) - (2.0*(j-2)*herm(j-2))
        END DO
      !=====================evaluate each herm for a single sobol point=========================!
      
      !=====================evaluate each matrix element for a single point=========================!
        DO k = 1, deg
             DO m = 1, deg
                 A(k,m) = A(k,m) + coef(k)*herm(k)*coef(m)*herm(m)
             END DO
        END DO
      !=====================evaluate each matrix element for a single point=========================!

  END DO
!=========================evaluate each sobol point=========================!
  A = A / Nsobol
  
!=========================write out matrix elements=========================!
  do o=1,deg
     Write(10,*) A(1:deg,o)
  enddo
!=========================write out matrix elements=========================!
  
  CLOSE(10)

END PROGRAM int_test
