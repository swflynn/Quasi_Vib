! 10/11/17
! Removed mbpol input to simplify code, only works for TIP4P
! Code Only Works For 3 DOF (Vmax 00000###), because we hardcoded in the HA

Module quasi_nm
 IMPLICIT NONE 
!============================================================================================!
!======================================Global paramaters=====================================!
!============================================================================================!
  DOUBLE PRECISION, PARAMETER:: deg=180/dacos(-1d0)
  DOUBLE PRECISION, PARAMETER:: pi=dacos(-1d0)
  DOUBLE PRECISION, PARAMETER:: bohr = 0.52917721092
  DOUBLE PRECISION, PARAMETER:: autocm = 2.194746313D5
  DOUBLE PRECISION, PARAMETER:: melectron=1822.88839
  DOUBLE PRECISION, PARAMETER:: Hmass = 1.00782503223*melectron
  DOUBLE PRECISION, PARAMETER:: Omass = 15.99491461957*melectron
!============================================================================================!
!=======================================Global Variables=====================================!
!============================================================================================!
  CHARACTER(LEN=5) potential
  DOUBLE PRECISION, ALLOCATABLE:: sqrt_mass(:),mass(:)
  CHARACTER(LEN=2), ALLOCATABLE:: atom_type(:)
  INTEGER:: Dim, Natoms, Jmax, Vtot, data_freq
  INTEGER, ALLOCATABLE :: v(:,:)
  INTEGER, PARAMETER :: Vmax(9) = (/0,0,0,0,0,0,6,6,6/)

CONTAINS

  SUBROUTINE CM(Natoms,q)
    IMPLICIT NONE 
    INTEGER:: Natoms,i
    DOUBLE PRECISION:: q(3,Natoms),vec(3)
    vec=0
    DO i=1,Natoms
       vec(:)=vec(:)+mass(i)*q(:,i)
    END DO
    vec=vec/sum(mass(1:Natoms))
    DO i=1,Natoms
       q(:,i)=q(:,i)-vec(:)
    END DO
  END SUBROUTINE CM
  
  FUNCTION Atom_mass(atom)
    IMPLICIT NONE
    DOUBLE PRECISION:: Atom_mass
    CHARACTER(LEN=2), INTENT(IN) :: atom
    IF (atom=='O') THEN
       Atom_mass=Omass
    ELSE IF (atom=='H') THEN
       Atom_mass=Hmass
    ELSE 
       WRITE(*,*) 'atom ', atom, ' is not recognized'
       STOP 
    END IF
  END FUNCTION Atom_mass

  subroutine frequencies_from_Hess(Dim,Hess,omega,U)
    implicit none
    integer :: i,IERR,Dim
    double precision :: Hess(Dim,Dim),A(Dim,Dim),omega(Dim),FV1(Dim),FV2(Dim),U(Dim,Dim)
    A=Hess
    call RS(Dim,Dim,A,omega,1,U,FV1,FV2,IERR) 
          write(*,*) 'Frequencies from the Hessian:'
    do i=Dim,1,-1
       omega(i)=sign(dsqrt(dabs(omega(i))),omega(i))
       write(*,*) omega(i)*autocm, 'normalized = 1?',sum(U(:,i)**2)
    enddo
  end subroutine frequencies_from_Hess
  
  subroutine Get_Hessian(q,H)
    implicit none
    integer :: i,j
    double precision ::  H(Dim,Dim),q(Dim),r(Dim),E,force(Dim),force0(Dim)
    double precision, parameter :: s=1d-7
    
    r=q
    call water_potential(Natoms/3, r, E, force0)
    do  i=1,Dim
       r(i)=q(i)+s
       call water_potential(Natoms/3, r, E, force)
       r(i)=q(i)
       do j=1,Dim
          H(i,j)=(force0(j)-force(j))/s
       enddo
    enddo
    ! symmetrize
    do i=1,Dim
       do j=1,i
          if(i.ne.j) H(i,j)=(H(i,j)+H(j,i))/2
          H(i,j)=H(i,j)/(sqrt_mass(i)*sqrt_mass(j)) ! mass-scaled Hessian    \tilde{K} in atomic units
          if(i.ne.j)  H(j,i)=H(i,j)
       enddo
    enddo
   ! write(*,*) 'Here is the mass scaled Hessian', H
  end subroutine Get_Hessian
  
  subroutine water_potential(NO,q,energy,force)
    USE iso_c_binding
    USE TIP4P_module
    IMPLICIT NONE
    
    INTEGER, INTENT(IN) :: NO                              ! number of water molecules
    DOUBLE PRECISION, DIMENSION(9*NO), INTENT(IN) :: q   ! coordinates
    DOUBLE PRECISION, DIMENSION(9*NO), INTENT(INOUT) :: force
    DOUBLE PRECISION, INTENT(INOUT) :: energy
    
    if(potential=='tip4p') then
       call TIP4P(NO, q, energy, force)
    else
       stop 'cannot identify the potential'
    endif
  end subroutine water_potential

SUBROUTINE permutation()
    Implicit none
    INTEGER :: j,vv(DIM),k,v1,v2,v3,v4,v5,v6,v7,v8,v9

    j=0
    if(DIM>9) stop 'Spatial_dim>9'
    do v1=0,Vmax(1)
       vv(1)=v1
       if(DIM>= 2) then
          do v2=0,min(Vtot-vv(1),Vmax(2))
             vv(2)=v2
             if(DIM>= 3) then
                do v3=0,min(Vtot-sum(vv(1:2)),Vmax(3))
                   vv(3)=v3
                   if(DIM>= 4) then
                      do v4=0,min(Vtot-sum(vv(1:3)),Vmax(4))
                         vv(4)=v4
                         if(DIM>= 5) then
                            do v5=0,min(Vtot-sum(vv(1:4)),Vmax(5))
                               vv(5)=v5
                               if(DIM>= 6) then
                                  do v6=0,min(Vtot-sum(vv(1:5)),Vmax(6))
                                     vv(6)=v6
                                     if(DIM>= 7) then
                                        do v7=0,min(Vtot-sum(vv(1:6)),Vmax(7))
                                           vv(7)=v7
                                           if(DIM>= 8) then
                                              do v8=0,min(Vtot-sum(vv(1:7)),Vmax(8))
                                                 vv(8)=v8
                                                 if(DIM== 9) then
                                                    do v9=0,min(Vtot-sum(vv(1:8)),Vmax(9))
                                                       vv(9)=v9
                                                       j=j+1
                                                    enddo
                                                 else
                                                    j=j+1
                                                 endif
                                              enddo
                                           else
                                              j=j+1
                                           endif
                                        enddo
                                     else
                                        j=j+1
                                     endif
                                  enddo
                               else
                                  j=j+1
                               endif
                            enddo
                         else 
                            j=j+1 
                         endif
                      enddo
                   else
                      j=j+1
                   endif
                enddo
             else
                j=j+1
             endif
          enddo
       else
          j=j+1
       endif
    enddo
    Jmax = j
!===================================With Jmax, Run again=================================!
    !WRITE(*,*) 'Jmax = ', Jmax
    ALLOCATE(v(DIM,Jmax))
    
    j=0
    if(DIM>9) stop 'Spatial_dim>9'
    do v1=0,Vmax(1)
       vv(1)=v1
       if(DIM>= 2) then
          do v2=0,min(Vtot-vv(1),Vmax(2))
             vv(2)=v2
             if(DIM>= 3) then
                do v3=0,min(Vtot-sum(vv(1:2)),Vmax(3))
                   vv(3)=v3
                   if(DIM>= 4) then
                      do v4=0,min(Vtot-sum(vv(1:3)),Vmax(4))
                         vv(4)=v4
                         if(DIM>= 5) then
                            do v5=0,min(Vtot-sum(vv(1:4)),Vmax(5))
                               vv(5)=v5
                               if(DIM>= 6) then
                                  do v6=0,min(Vtot-sum(vv(1:5)),Vmax(6))
                                     vv(6)=v6
                                     if(DIM>= 7) then
                                        do v7=0,min(Vtot-sum(vv(1:6)),Vmax(7))
                                           vv(7)=v7
                                           if(DIM>= 8) then
                                              do v8=0,min(Vtot-sum(vv(1:7)),Vmax(8))
                                                 vv(8)=v8
                                                 if(DIM== 9) then
                                                    do v9=0,min(Vtot-sum(vv(1:8)),Vmax(9))
                                                       vv(9)=v9
                                                       j=j+1
                                                       v(:,j)=vv 
                                                    enddo
                                                 else
                                                    j=j+1
                                                    v(:,j)=vv           
                                                 endif
                                              enddo
                                           else
                                              j=j+1
                                              v(:,j)=vv           
                                           endif
                                        enddo
                                     else
                                        j=j+1
                                        v(:,j)=vv           
                                     endif
                                  enddo
                               else
                                  j=j+1
                                  v(:,j)=vv                            
                               endif
                            enddo
                         else 
                            j=j+1 
                            v(:,j)=vv
                         endif
                      enddo
                   else
                      j=j+1
                      v(:,j)=vv           
                   endif
                enddo
             else
                j=j+1
                v(:,j)=vv           
             endif
          enddo
       else
          j=j+1
          v(:,j)=vv           
       endif
    enddo
!    write(*,*) v   ! V is potentially very large!
END SUBROUTINE permutation

END MODULE quasi_nm
!===========================================================================================!
!===========================Begin qMC Harmonic Approximation ===============================!
!===========================================================================================!
PROGRAM main
USE quasi_nm
  
  IMPLICIT NONE
  real :: initial_time, final_time  
  integer(kind=8) :: skip
  integer :: Nsobol, i,j, i1, j2(1), jj
  double precision, allocatable :: omega(:), Hess(:,:), U(:,:), q(:), q0(:)
  double precision, allocatable :: q1(:), force(:)
  double precision :: freq_cutoff, E, V0, potdif,harm_pot
  character(len=50) coord_in
  DOUBLE PRECISION, ALLOCATABLE :: y(:), herm(:,:), A(:,:,:), Umat(:,:), U1mat(:,:)
  DOUBLE PRECISION, ALLOCATABLE :: C(:,:), FV1(:), FV2(:), eigenvalue(:), eigenvec(:,:)
  INTEGER:: m, n, IERR, j1, k
  DOUBLE PRECISION :: B, E0(1), E1(1), E2(1), E3(1), EP1(1), EP2(1), EP3(1), pert
!==========================================================================================!
!===============================Variables to run ssobol.f==================================!
!==========================================================================================!
  INTEGER :: TAUS, IFLAG, max_seq, SAM
  LOGICAL :: FLAG(2)
!===========================================================================================!
!====================================Read Input File========================================! 
!===========================================================================================! 
  CALL CPU_TIME(initial_time)
  OPEN(60,FILE='input.dat')
  READ(60,*) Vtot
  READ(60,*) potential                
  READ(60,*) coord_in
  READ(60,*) freq_cutoff
  READ(60,*) Nsobol
  READ(60,*) skip
  READ(60,*) data_freq
  READ(60,*) pert
  CLOSE(60)
  freq_cutoff = freq_cutoff / autocm
WRITE(*,*) 'Test 1; Successfully Read Input File!'
!==========================================================================================!
!===============================Variables to run ssobol.f==================================!
!==========================================================================================!
  SAM = 1
  max_seq = 30
  IFLAG = 1
!===========================================================================================!
!======================================Read xyz File========================================! 
!===========================================================================================!
  OPEN(61,File=coord_in)
  READ(61,*) Natoms
  READ(61,*)
  Dim= 3*Natoms ! cartesian coordinates
WRITE(*,*) 'Test 2; Successfully Read in Coordinates!'
!===========================================================================================!
!===============================Allocate Arrays=============================================!
!===========================================================================================! 
  ALLOCATE(omega(Dim), atom_type(Natoms), sqrt_mass(Dim), mass(Natoms), &
       q(Dim), q0(Dim), force(Dim), Hess(Dim,Dim), U(Dim,Dim))
!===========================================================================================!
!============================Read Atom Type, get mass=======================================! 
!==============q0 contains x,y,z coordinates of initial water  configuration================!
!===========================================================================================!
  DO i=1,Natoms
     READ(61,*) atom_type(i), q0(3*i-2:3*i)   ! coordinates in Angstroms
     mass(i)=Atom_mass(atom_type(i))
     sqrt_mass(3*i-2:3*i)=SQRT(mass(i))
  END DO
  CLOSE(61) 
  q0=q0/bohr            ! convert coordinates to atomic units
WRITE(*,*) 'Test 3; Successfully Converted Coordinates to Atomic Units'
!===========================================================================================!
!====================================Equ Config=============================================! 
!===========================================================================================!
  CALL water_potential(Natoms/3, q0, E, force)
WRITE(*,*) 'Test 5; Successfully Evaluate Potential Zero-Point'
!===========================================================================================!
!====================================Hessian Frequencies====================================! 
!===========================================================================================!
CALL Get_Hessian(q0,Hess)
CALL frequencies_from_Hess(Dim,Hess,omega,U)
! Compute the Harmonic Approximation
DO i=7,9
  E = E + omega(i)*autocm/2
END DO
WRITE(*,*) 'HA~ ground state minimum E= : ', E
WRITE(*,*) 'Test 6; Successfully Compute Hessian and Frequencies'
!===========================================================================================!
!==================================Normal Modes U(dim,dim)==================================! 
!==============================sqrt(.5) comes from std normal dist==========================!
!===========================================================================================!
Hess=0d0
DO k=1,Dim
   IF (omega(k)<freq_cutoff) THEN
      omega(k) = freq_cutoff
   END IF

! Compute Hessian 
   do i=1,Dim
      do j=1,Dim
         Hess(i,j)=Hess(i,j)+ omega(k)**2*U(i,k)*U(j,k)
      enddo
   enddo
   DO i = 1, Dim
      U(i,k) = SQRT(1/omega(k)) / sqrt_mass(i)*U(i,k)   
   END DO
END DO ! loop over eigenvalues
WRITE(*,*) 'Test 7; Successfully Compute Normal Modes'
!===========================================================================================!
!============================Determine Jmax and Permutations================================!
!===========================================================================================!
  CALL permutation()
  ALLOCATE(Umat(Jmax,Jmax), U1mat(Jmax,Jmax), C(Jmax,Jmax), FV1(Jmax), FV2(Jmax))
  ALLOCATE(eigenvalue(Jmax), eigenvec(Jmax,Jmax))
  ALLOCATE(y(dim), herm(0:Vtot,dim), A(0:Vtot,0:Vtot,dim))

  Umat=0d0  ! initialize PE matrix
  U1mat=0d0 
  OPEN(UNIT=80, FILE='matrix.dat')
  OPEN(UNIT=81, FILE='eigenvalues.dat')
  OPEN(UNIT=82, FILE='eigenvectors.dat')
  OPEN(UNIT=83, FILE='fundamentals.dat')
  OPEN(UNIT=84, FILE='weight.dat')
  OPEN(UNIT=85, FILE='harmonic.dat')
WRITE(*,*) 'Test 8; Successfully Allocate Arrays '
!===========================================================================================!
!================================Loop over Sobol Points=====================================!
!===============================Normalize with Gaussian=====================================!
!=============Calculate (our normalization) Hermite's, up to Vtot, ini poly=0 ==============!
!===========================================================================================!
  CALL INSSOBL(FLAG,dim,Nsobol,TAUS,y,max_seq,IFLAG)
WRITE(*,*) 'Test 9; Successfully Define Sobol Scrambling Method'
  DO i = 1, Nsobol
     CALL GOSSOBL(y)
     CALL sobol_stdnormal(dim, y)
     y = y/SQRT(2.)    ! factor from definition of normal distribution
     herm(0,:) = 1.0                       ! Re-normalized hermite polynomial now
     herm(1,:) = SQRT(2.)*y(:)       
     DO j = 2,Vtot      
        herm(j,:) = (SQRT(2./j)*y(:)*herm(j-1,:)) - (SQRT(((j-1d0)/j))*herm(j-2,:))
     END DO
!write(*,*) 'Test 10 Check at sobol point: ', i !testing remove after
!===========================================================================================!
!===================================Evaluate Herm * Herm ===================================!
!==========================Matrix A: herm(deg)*herm(deg), deg(0,Vtot)=======================!
!===========================================================================================!
     DO m=0,Vtot
        DO n=0,Vtot
           A(m,n,:) = herm(m,:)*herm(n,:)
        END DO
     END DO
!===========================================================================================!
!===================================Monte Carlo=============================================!
!===========================================================================================!
     q1=q0
     DO j =1,Dim
        q1(:) = q1(:) + y(j)*U(:,j)
     END DO
potdif = 0d0
      DO j=7,Dim   ! 
        potdif = potdif+ pert*(1*omega(j)*y(j)**2)      ! if 0.5=1, get result off by factor of 2!
      END DO
!===========================================================================================!
!================================Evaluate Matrix Elements ==================================!
!===============Matrix Umat: PE matrix elements. U1mat for partial average==================!
!===========================================================================================!
     DO j=1,Jmax         
        DO j1=j,Jmax 
           B=potdif
           DO k=1,Dim         
              B=B*A(v(k,j),v(k,j1),k)
           END DO
           U1mat(j1,j) = U1mat(j1,j) + B
        END DO
     END DO
!===========================================================================================!
!===================================Partial Average and Flush===============================!
!===========================================================================================!
     IF(MOD(i,data_freq)==0) THEN
        Umat = Umat + U1mat
        U1mat = 0d0
        C=Umat/i
      write(*,*) 'iteration: ', i
!===========================================================================================!
!===============================Symmetrize Matrix For Eigenvalues===========================!
!===========================================================================================!
        DO j=1,Jmax-1  
           DO j1=j+1,Jmax 
              C(j,j1) = C(j1,j) 
           END DO
        END DO

        DO j=1,Jmax
            DO k=1,DIM
              C(j,j)=C(j,j)+omega(k)*(v(k,j)+0.5)   
            END DO 
        END DO 

        WRITE(80,*) i
        do jj = 1,Jmax
            write(80,*) C(:,jj)*autocm !Writes matrix column wise
        end do
        CALL RS(Jmax,Jmax,C,eigenvalue,1,eigenvec,FV1,FV2,IERR)
        WRITE(81,*) i, eigenvalue(:)
        WRITE(82,*) i, eigenvec(:,:)
!===========================================================================================!
!===============================Analyze ground and Fundamental Freq=========================!
!===========================================================================================!
  E0 = 0d0
  E1 = 0d0
  E2 = 0d0
  E3 = 0d0
do i1 = 1,Jmax
  if(all(v(:,i1)==(/0,0,0,0,0,0,0,0,0/))) then
      j2=maxloc(abs(eigenvec(i1,:)))
      E0 = eigenvalue(j2)*autocm
      write(*,*) 'j2, index =: ', j2
      write(*,*) 'E0=',E0,'  state=',v(7:9,i1), ' i1 index=', &
      i1,'  weight=', eigenvec(i1,j2)**2
     write(*,*) i, v(7:9,i1), E0, eigenvec(i1,j2)**2
     write(84,*) i, v(7:9,i1), E0, eigenvec(i1,j2)**2

 else if(all(v(:,i1)==(/0,0,0,0,0,0,1,0,0/))) then
      j2=maxloc(abs(eigenvec(i1,:)))
      E1 = eigenvalue(j2)*autocm
      write(*,*) 'j2, index =: ', j2
      write(*,*) 'E1=', E1,'  state=',v(7:9,i1), ' i1 index=', &
      i1,'  weight=', eigenvec(i1,j2)**2
     write(*,*) i, v(7:9,i1), E1, eigenvec(i1,j2)**2
     write(84,*) i, v(7:9,i1), E1, eigenvec(i1,j2)**2

 else if(all(v(:,i1)==(/0,0,0,0,0,0,0,1,0/))) then
      j2=maxloc(abs(eigenvec(i1,:)))
      E2 = eigenvalue(j2)*autocm
      write(*,*) 'j2, index =: ', j2
      write(*,*) 'E2=', E2,'  state=',v(7:9,i1), ' i1 index=', &
      i1,'  weight=', eigenvec(i1,j2)**2
     write(*,*) i, v(7:9,i1), E2, eigenvec(i1,j2)**2
     write(84,*) i, v(7:9,i1), E2, eigenvec(i1,j2)**2

 else if(all(v(:,i1)==(/0,0,0,0,0,0,0,0,1/))) then
      j2=maxloc(abs(eigenvec(i1,:)))
      E3 = eigenvalue(j2)*autocm
      write(*,*) 'j2, index =: ', j2
      write(*,*) 'E3=', E3,'  state=',v(7:9,i1), ' i1 index=', &
      i1,'  weight=', eigenvec(i1,j2)**2
     write(*,*) i, v(7:9,i1), E3, eigenvec(i1,j2)**2
     write(84,*) i, v(7:9,i1), E3, eigenvec(i1,j2)**2
 endif

end do
!Pertebation analysis! 
 write(83,*) i,E0, E1 - E0, E2-E0, E3-E0
 EP1 = (E1-E0) / (pert+1)
 EP2 = (E2-E0) / (pert+1)
 EP3 = (E3-E0) / (pert+1)

write(85,*) i, (E1-E0) - (0.5*((E1-E0) - EP1)), (E2-E0) - (0.5*((E2-E0) - EP2)), (E3-E0) - (0.5*((E3-E0) - EP3))

        FLUSH(80)
        FLUSH(81)
        FLUSH(82)
        FLUSH(83)
      END IF

  END DO ! end loop over sobol points
  CLOSE(UNIT=80)
  CLOSE(UNIT=81)
  CLOSE(UNIT=82)
  CLOSE(UNIT=83)
  CLOSE(UNIT=84)
  CLOSE(UNIT=85)

CALL CPU_TIME(final_time)
WRITE(*,*) 'Final Check Successful; Hello Universe!'
WRITE(*,*) 'TOTAL TIME: ', final_time - initial_time
!===========================================================================================!
!========================================output.dat=========================================! 
!===========================================================================================!
 OPEN(90,FILE='simulation.dat')
 WRITE(90,*) 'Here is the output file for your calculation'
 WRITE(90,*) 'Natoms=                     ', Natoms
 WRITE(90,*) 'Dim=                        ', Dim
 WRITE(90,*) 'Vmax =                      ', Vmax
 WRITE(90,*) 'Vtot =                      ', Vtot
 WRITE(90,*) 'Jmax =                      ', Jmax
 WRITE(90,*) 'potential=                  ', potential
 WRITE(90,*) 'Nsobol=                     ', Nsobol
 WRITE(90,*) 'freq_cutoff=                     ', freq_cutoff
 WRITE(90,*) 'skip=                       ', skip
 WRITE(90,*) 'coord_in=                   ', coord_in
 WRITE(90,*) 'The HA ~ gave an energy of =  ', E
 WRITE(90,*) 'Calculation total time (s)  ', final_time - initial_time
 WRITE(90,*) 'Fundamental Frequency Calculation!'
 CLOSE(90)

END PROGRAM main
