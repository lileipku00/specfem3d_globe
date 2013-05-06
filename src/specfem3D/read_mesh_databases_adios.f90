!=====================================================================
!
!          S p e c f e m 3 D  G l o b e  V e r s i o n  5 . 1
!          --------------------------------------------------
!
!          Main authors: Dimitri Komatitsch and Jeroen Tromp
!                        Princeton University, USA
!             and University of Pau / CNRS / INRIA, France
! (c) Princeton University / California Institute of Technology and University of Pau / CNRS / INRIA
!                            April 2011
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
!=====================================================================

!-------------------------------------------------------------------------------------------------

  subroutine read_mesh_databases_CM_adios()

! mesh for CRUST MANTLE region

  use specfem_par
  use specfem_par_crustmantle
  implicit none

  ! local parameters
  integer :: nspec_iso,nspec_tiso,nspec_ani
  logical :: READ_KAPPA_MU,READ_TISO
  ! dummy array that does not need to be actually read
  integer, dimension(:),allocatable :: dummy_idoubling
  integer :: ierr

  ! crust and mantle

  if(ANISOTROPIC_3D_MANTLE_VAL) then
    READ_KAPPA_MU = .false.
    READ_TISO = .false.
    nspec_iso = NSPECMAX_ISO_MANTLE ! 1
    nspec_tiso = NSPECMAX_TISO_MANTLE ! 1
    nspec_ani = NSPEC_CRUST_MANTLE
  else
    READ_KAPPA_MU = .true.
    nspec_iso = NSPEC_CRUST_MANTLE
    if(TRANSVERSE_ISOTROPY_VAL) then
      nspec_tiso = NSPECMAX_TISO_MANTLE
    else
      nspec_tiso = 1
    endif
    nspec_ani = NSPECMAX_ANISO_MANTLE ! 1
    READ_TISO = .true.
  endif

  ! sets number of top elements for surface movies & noise tomography
  NSPEC_TOP = NSPEC2D_TOP(IREGION_CRUST_MANTLE)

  ! allocates mass matrices in this slice (will be fully assembled in the solver)
  !
  ! in the case of stacey boundary conditions, add C*deltat/2 contribution to the mass matrix
  ! on Stacey edges for the crust_mantle and outer_core regions but not for the inner_core region
  ! thus the mass matrix must be replaced by three mass matrices including the "C" damping matrix
  !
  ! if absorbing_conditions are not set or if NCHUNKS=6, only one mass matrix is needed
  ! for the sake of performance, only "rmassz" array will be filled and "rmassx" & "rmassy" will be obsolete
  if(NCHUNKS_VAL /= 6 .and. ABSORBING_CONDITIONS) then
     NGLOB_XY_CM = NGLOB_CRUST_MANTLE
  else
     NGLOB_XY_CM = 1
  endif

  ! allocates dummy array
  allocate(dummy_idoubling(NSPEC_CRUST_MANTLE),stat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error allocating dummy idoubling in crust_mantle')

  ! allocates mass matrices
  allocate(rmassx_crust_mantle(NGLOB_XY_CM), &
          rmassy_crust_mantle(NGLOB_XY_CM),stat=ierr)
  if(ierr /= 0) stop 'error allocating dummy rmassx, rmassy in crust_mantle'
  allocate(rmassz_crust_mantle(NGLOB_CRUST_MANTLE),stat=ierr)
  if(ierr /= 0) stop 'error allocating rmassz in crust_mantle'

  ! reads databases file
  call read_arrays_solver(IREGION_CRUST_MANTLE,myrank, &
            NSPEC_CRUST_MANTLE,NGLOB_CRUST_MANTLE,NGLOB_XY_CM, &
            nspec_iso,nspec_tiso,nspec_ani, &
            rho_vp_crust_mantle,rho_vs_crust_mantle, &
            xstore_crust_mantle,ystore_crust_mantle,zstore_crust_mantle, &
            xix_crust_mantle,xiy_crust_mantle,xiz_crust_mantle, &
            etax_crust_mantle,etay_crust_mantle,etaz_crust_mantle, &
            gammax_crust_mantle,gammay_crust_mantle,gammaz_crust_mantle, &
            rhostore_crust_mantle,kappavstore_crust_mantle,muvstore_crust_mantle, &
            kappahstore_crust_mantle,muhstore_crust_mantle,eta_anisostore_crust_mantle, &
            c11store_crust_mantle,c12store_crust_mantle,c13store_crust_mantle, &
            c14store_crust_mantle,c15store_crust_mantle,c16store_crust_mantle, &
            c22store_crust_mantle,c23store_crust_mantle,c24store_crust_mantle, &
            c25store_crust_mantle,c26store_crust_mantle,c33store_crust_mantle, &
            c34store_crust_mantle,c35store_crust_mantle,c36store_crust_mantle, &
            c44store_crust_mantle,c45store_crust_mantle,c46store_crust_mantle, &
            c55store_crust_mantle,c56store_crust_mantle,c66store_crust_mantle, &
            ibool_crust_mantle,dummy_idoubling,ispec_is_tiso_crust_mantle, &
            rmassx_crust_mantle,rmassy_crust_mantle,rmassz_crust_mantle,rmass_ocean_load, &
            READ_KAPPA_MU,READ_TISO, &
            ABSORBING_CONDITIONS,LOCAL_PATH)

  ! check that the number of points in this slice is correct
  if(minval(ibool_crust_mantle(:,:,:,:)) /= 1 .or. &
    maxval(ibool_crust_mantle(:,:,:,:)) /= NGLOB_CRUST_MANTLE) &
      call exit_MPI(myrank,'incorrect global numbering: iboolmax does not equal nglob in crust and mantle')

  deallocate(dummy_idoubling)

  end subroutine read_mesh_databases_CM_adios

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_OC_adios()

! mesh for OUTER CORE region

  use specfem_par
  use specfem_par_outercore
  implicit none

  ! local parameters
  integer :: nspec_iso,nspec_tiso,nspec_ani,NGLOB_XY_dummy
  logical :: READ_KAPPA_MU,READ_TISO
  integer :: ierr

  ! dummy array that does not need to be actually read
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,1) :: dummy_array
  real(kind=CUSTOM_REAL), dimension(:), allocatable :: dummy_rmass

  logical, dimension(:), allocatable :: dummy_ispec_is_tiso
  integer, dimension(:), allocatable :: dummy_idoubling_outer_core

  ! outer core (no anisotropy nor S velocity)
  ! rmass_ocean_load is not used in this routine because it is meaningless in the outer core
  READ_KAPPA_MU = .false.
  READ_TISO = .false.
  nspec_iso = NSPEC_OUTER_CORE
  nspec_tiso = 1
  nspec_ani = 1

  ! dummy allocation
  NGLOB_XY_dummy = 1

  allocate(dummy_rmass(NGLOB_XY_dummy), &
          dummy_ispec_is_tiso(NSPEC_OUTER_CORE), &
          dummy_idoubling_outer_core(NSPEC_OUTER_CORE), &
          stat=ierr)
  if(ierr /= 0) stop 'error allocating dummy rmass and dummy ispec/idoubling in outer core'

  ! allocates mass matrices in this slice (will be fully assembled in the solver)
  !
  ! in the case of stacey boundary conditions, add C*deltat/2 contribution to the mass matrix
  ! on Stacey edges for the crust_mantle and outer_core regions but not for the inner_core region
  ! thus the mass matrix must be replaced by three mass matrices including the "C" damping matrix
  !
  ! if absorbing_conditions are not set or if NCHUNKS=6, only one mass matrix is needed
  ! for the sake of performance, only "rmassz" array will be filled and "rmassx" & "rmassy" will be obsolete
  allocate(rmass_outer_core(NGLOB_OUTER_CORE),stat=ierr)
  if(ierr /= 0) stop 'error allocating rmass in outer core'

  call read_arrays_solver(IREGION_OUTER_CORE,myrank, &
            NSPEC_OUTER_CORE,NGLOB_OUTER_CORE,NGLOB_XY_dummy, &
            nspec_iso,nspec_tiso,nspec_ani, &
            vp_outer_core,dummy_array, &
            xstore_outer_core,ystore_outer_core,zstore_outer_core, &
            xix_outer_core,xiy_outer_core,xiz_outer_core, &
            etax_outer_core,etay_outer_core,etaz_outer_core, &
            gammax_outer_core,gammay_outer_core,gammaz_outer_core, &
            rhostore_outer_core,kappavstore_outer_core,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            ibool_outer_core,dummy_idoubling_outer_core,dummy_ispec_is_tiso, &
            dummy_rmass,dummy_rmass,rmass_outer_core,rmass_ocean_load, &
            READ_KAPPA_MU,READ_TISO, &
            ABSORBING_CONDITIONS,LOCAL_PATH)

  deallocate(dummy_idoubling_outer_core,dummy_ispec_is_tiso,dummy_rmass)

  ! check that the number of points in this slice is correct
  if(minval(ibool_outer_core(:,:,:,:)) /= 1 .or. &
     maxval(ibool_outer_core(:,:,:,:)) /= NGLOB_OUTER_CORE) &
    call exit_MPI(myrank,'incorrect global numbering: iboolmax does not equal nglob in outer core')

  end subroutine read_mesh_databases_OC_adios

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_IC_adios()

! mesh for INNER CORE region

  use specfem_par
  use specfem_par_innercore
  implicit none

  ! local parameters
  integer :: nspec_iso,nspec_tiso,nspec_ani,NGLOB_XY_dummy
  logical :: READ_KAPPA_MU,READ_TISO
  integer :: ierr

  ! dummy array that does not need to be actually read
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,1) :: dummy_array
  real(kind=CUSTOM_REAL), dimension(:), allocatable :: dummy_rmass
  logical, dimension(:),allocatable:: dummy_ispec_is_tiso

  ! inner core (no anisotropy)
  ! rmass_ocean_load is not used in this routine because it is meaningless in the inner core
  READ_KAPPA_MU = .true. ! (muvstore needed for attenuation)
  READ_TISO = .false.
  nspec_iso = NSPEC_INNER_CORE
  nspec_tiso = 1
  if(ANISOTROPIC_INNER_CORE_VAL) then
    nspec_ani = NSPEC_INNER_CORE
  else
    nspec_ani = 1
  endif

  ! dummy allocation
  NGLOB_XY_dummy = 1

  allocate(dummy_rmass(NGLOB_XY_dummy), &
          dummy_ispec_is_tiso(NSPEC_INNER_CORE), &
          stat=ierr)
  if(ierr /= 0) stop 'error allocating dummy rmass and dummy ispec in inner core'

  ! allocates mass matrices in this slice (will be fully assembled in the solver)
  !
  ! in the case of stacey boundary conditions, add C*deltat/2 contribution to the mass matrix
  ! on Stacey edges for the crust_mantle and outer_core regions but not for the inner_core region
  ! thus the mass matrix must be replaced by three mass matrices including the "C" damping matrix
  !
  ! if absorbing_conditions are not set or if NCHUNKS=6, only one mass matrix is needed
  ! for the sake of performance, only "rmassz" array will be filled and "rmassx" & "rmassy" will be obsolete
  allocate(rmass_inner_core(NGLOB_INNER_CORE),stat=ierr)
  if(ierr /= 0) stop 'error allocating rmass in inner core'

  call read_arrays_solver(IREGION_INNER_CORE,myrank, &
            NSPEC_INNER_CORE,NGLOB_INNER_CORE,NGLOB_XY_dummy, &
            nspec_iso,nspec_tiso,nspec_ani, &
            dummy_array,dummy_array, &
            xstore_inner_core,ystore_inner_core,zstore_inner_core, &
            xix_inner_core,xiy_inner_core,xiz_inner_core, &
            etax_inner_core,etay_inner_core,etaz_inner_core, &
            gammax_inner_core,gammay_inner_core,gammaz_inner_core, &
            rhostore_inner_core,kappavstore_inner_core,muvstore_inner_core, &
            dummy_array,dummy_array,dummy_array, &
            c11store_inner_core,c12store_inner_core,c13store_inner_core, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            dummy_array,dummy_array,c33store_inner_core, &
            dummy_array,dummy_array,dummy_array, &
            c44store_inner_core,dummy_array,dummy_array, &
            dummy_array,dummy_array,dummy_array, &
            ibool_inner_core,idoubling_inner_core,dummy_ispec_is_tiso, &
            dummy_rmass,dummy_rmass,rmass_inner_core,rmass_ocean_load, &
            READ_KAPPA_MU,READ_TISO, &
            ABSORBING_CONDITIONS,LOCAL_PATH)

  deallocate(dummy_ispec_is_tiso,dummy_rmass)

  ! check that the number of points in this slice is correct
  if(minval(ibool_inner_core(:,:,:,:)) /= 1 .or. maxval(ibool_inner_core(:,:,:,:)) /= NGLOB_INNER_CORE) &
    call exit_MPI(myrank,'incorrect global numbering: iboolmax does not equal nglob in inner core')

  end subroutine read_mesh_databases_IC_adios

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_coupling_adios()

! to couple mantle with outer core

  use specfem_par
  use specfem_par_crustmantle
  use specfem_par_innercore
  use specfem_par_outercore

  implicit none

  include 'mpif.h'

  ! local parameters
  integer :: njunk1,njunk2,njunk3
  integer :: ierr

  ! crust and mantle
  ! create name of database
  call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

  ! Stacey put back
  open(unit=27,file=prname(1:len_trim(prname))//'boundary.bin', &
        status='old',form='unformatted',action='read',iostat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error opening crust_mantle boundary.bin file')

  read(27) nspec2D_xmin_crust_mantle
  read(27) nspec2D_xmax_crust_mantle
  read(27) nspec2D_ymin_crust_mantle
  read(27) nspec2D_ymax_crust_mantle
  read(27) njunk1
  read(27) njunk2

! boundary parameters
  read(27) ibelm_xmin_crust_mantle
  read(27) ibelm_xmax_crust_mantle
  read(27) ibelm_ymin_crust_mantle
  read(27) ibelm_ymax_crust_mantle
  read(27) ibelm_bottom_crust_mantle
  read(27) ibelm_top_crust_mantle

  read(27) normal_xmin_crust_mantle
  read(27) normal_xmax_crust_mantle
  read(27) normal_ymin_crust_mantle
  read(27) normal_ymax_crust_mantle
  read(27) normal_bottom_crust_mantle
  read(27) normal_top_crust_mantle

  read(27) jacobian2D_xmin_crust_mantle
  read(27) jacobian2D_xmax_crust_mantle
  read(27) jacobian2D_ymin_crust_mantle
  read(27) jacobian2D_ymax_crust_mantle
  read(27) jacobian2D_bottom_crust_mantle
  read(27) jacobian2D_top_crust_mantle
  close(27)


  ! read parameters to couple fluid and solid regions
  !
  ! outer core

  ! create name of database
  call create_name_database(prname,myrank,IREGION_OUTER_CORE,LOCAL_PATH)

  ! boundary parameters

  ! Stacey put back
  open(unit=27,file=prname(1:len_trim(prname))//'boundary.bin', &
        status='old',form='unformatted',action='read',iostat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error opening outer_core boundary.bin file')

  read(27) nspec2D_xmin_outer_core
  read(27) nspec2D_xmax_outer_core
  read(27) nspec2D_ymin_outer_core
  read(27) nspec2D_ymax_outer_core
  read(27) njunk1
  read(27) njunk2

  nspec2D_zmin_outer_core = NSPEC2D_BOTTOM(IREGION_OUTER_CORE)

  read(27) ibelm_xmin_outer_core
  read(27) ibelm_xmax_outer_core
  read(27) ibelm_ymin_outer_core
  read(27) ibelm_ymax_outer_core
  read(27) ibelm_bottom_outer_core
  read(27) ibelm_top_outer_core

  read(27) normal_xmin_outer_core
  read(27) normal_xmax_outer_core
  read(27) normal_ymin_outer_core
  read(27) normal_ymax_outer_core
  read(27) normal_bottom_outer_core
  read(27) normal_top_outer_core

  read(27) jacobian2D_xmin_outer_core
  read(27) jacobian2D_xmax_outer_core
  read(27) jacobian2D_ymin_outer_core
  read(27) jacobian2D_ymax_outer_core
  read(27) jacobian2D_bottom_outer_core
  read(27) jacobian2D_top_outer_core
  close(27)


  !
  ! inner core
  !

  ! create name of database
  call create_name_database(prname,myrank,IREGION_INNER_CORE,LOCAL_PATH)

  ! read info for vertical edges for central cube matching in inner core
  open(unit=27,file=prname(1:len_trim(prname))//'boundary.bin', &
        status='old',form='unformatted',action='read',iostat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error opening inner_core boundary.bin file')

  read(27) nspec2D_xmin_inner_core
  read(27) nspec2D_xmax_inner_core
  read(27) nspec2D_ymin_inner_core
  read(27) nspec2D_ymax_inner_core
  read(27) njunk1
  read(27) njunk2

  ! boundary parameters
  read(27) ibelm_xmin_inner_core
  read(27) ibelm_xmax_inner_core
  read(27) ibelm_ymin_inner_core
  read(27) ibelm_ymax_inner_core
  read(27) ibelm_bottom_inner_core
  read(27) ibelm_top_inner_core
  close(27)


  ! -- Boundary Mesh for crust and mantle ---
  if (SAVE_BOUNDARY_MESH .and. SIMULATION_TYPE == 3) then

    call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

    open(unit=27,file=prname(1:len_trim(prname))//'boundary_disc.bin', &
          status='old',form='unformatted',action='read',iostat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error opening boundary_disc.bin file')

    read(27) njunk1,njunk2,njunk3
    if (njunk1 /= NSPEC2D_MOHO .and. njunk2 /= NSPEC2D_400 .and. njunk3 /= NSPEC2D_670) &
               call exit_mpi(myrank, 'Error reading ibelm_disc.bin file')
    read(27) ibelm_moho_top
    read(27) ibelm_moho_bot
    read(27) ibelm_400_top
    read(27) ibelm_400_bot
    read(27) ibelm_670_top
    read(27) ibelm_670_bot
    read(27) normal_moho
    read(27) normal_400
    read(27) normal_670
    close(27)

    k_top = 1
    k_bot = NGLLZ

    ! initialization
    moho_kl = 0.; d400_kl = 0.; d670_kl = 0.; cmb_kl = 0.; icb_kl = 0.
  endif

  end subroutine read_mesh_databases_coupling_adios

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_addressing_adios()

  use specfem_par
  use specfem_par_crustmantle
  use specfem_par_innercore
  use specfem_par_outercore

  implicit none

  include 'mpif.h'

  ! local parameters
  integer, dimension(NCHUNKS_VAL,0:NPROC_XI_VAL-1,0:NPROC_ETA_VAL-1) :: addressing
  integer, dimension(0:NPROCTOT_VAL-1) :: ichunk_slice,iproc_xi_slice,iproc_eta_slice
  integer :: ierr,iproc,iproc_read,iproc_xi,iproc_eta

  ! open file with global slice number addressing
  if(myrank == 0) then
    open(unit=IIN,file=trim(OUTPUT_FILES)//'/addressing.txt',status='old',action='read',iostat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error opening addressing.txt')

    do iproc = 0,NPROCTOT_VAL-1
      read(IIN,*) iproc_read,ichunk,iproc_xi,iproc_eta

      if(iproc_read /= iproc) call exit_MPI(myrank,'incorrect slice number read')

      addressing(ichunk,iproc_xi,iproc_eta) = iproc
      ichunk_slice(iproc) = ichunk
      iproc_xi_slice(iproc) = iproc_xi
      iproc_eta_slice(iproc) = iproc_eta
    enddo
    close(IIN)
  endif

  ! broadcast the information read on the master to the nodes
  call MPI_BCAST(addressing,NCHUNKS_VAL*NPROC_XI_VAL*NPROC_ETA_VAL,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(ichunk_slice,NPROCTOT_VAL,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(iproc_xi_slice,NPROCTOT_VAL,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(iproc_eta_slice,NPROCTOT_VAL,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)

  ! output a topology map of slices - fix 20x by nproc
  if (myrank == 0 ) then
    if( NCHUNKS_VAL == 6 .and. NPROCTOT_VAL < 1000 ) then
      write(IMAIN,*) 'Spatial distribution of the slices'
      do iproc_xi = NPROC_XI_VAL-1, 0, -1
        write(IMAIN,'(20x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_AB
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(1x)',advance='yes')
      enddo
      write(IMAIN, *) ' '
      do iproc_xi = NPROC_XI_VAL-1, 0, -1
        write(IMAIN,'(1x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_BC
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(3x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_AC
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(3x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_BC_ANTIPODE
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(1x)',advance='yes')
      enddo
      write(IMAIN, *) ' '
      do iproc_xi = NPROC_XI_VAL-1, 0, -1
        write(IMAIN,'(20x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_AB_ANTIPODE
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(1x)',advance='yes')
      enddo
      write(IMAIN, *) ' '
      do iproc_xi = NPROC_XI_VAL-1, 0, -1
        write(IMAIN,'(20x)',advance='no')
        do iproc_eta = NPROC_ETA_VAL -1, 0, -1
          ichunk = CHUNK_AC_ANTIPODE
          write(IMAIN,'(i5)',advance='no') addressing(ichunk,iproc_xi,iproc_eta)
        enddo
        write(IMAIN,'(1x)',advance='yes')
      enddo
      write(IMAIN, *) ' '
    endif
  endif

  ! determine chunk number and local slice coordinates using addressing
  ! (needed for stacey conditions)
  ichunk = ichunk_slice(myrank)

  end subroutine read_mesh_databases_addressing_adios


!-------------------------------------------------------------------------------
!> \brief Read crust mantle MPI arrays from an ADIOS file.
  subroutine read_mesh_databases_MPI_CM_adios()
  ! External imports
  use mpi
  use adios_read_mod
  ! Internal imports
  use specfem_par
  use specfem_par_crustmantle

  use specfem_par
  use specfem_par_crustmantle
  implicit none

  ! local parameters
  integer :: sizeprocs, comm, ierr
  character(len=150) :: file_name
  integer(kind=8) :: group_size_inc
  integer :: local_dim, global_dim, offset
  ! ADIOS variables
  integer                 :: adios_err
  integer(kind=8)         :: adios_group, adios_handle, varid, sel
  integer(kind=8)         :: adios_groupsize, adios_totalsize
  integer :: vars_count, attrs_count, current_step, last_step, vsteps
  character(len=128), dimension(:), allocatable :: adios_names 
  integer(kind=8), dimension(1) :: start, count

  ! create the name for the database of the current slide and region
  call create_name_database_adios(prname, IREGION_CRUST_MANTLE, LOCAL_PATH)

  file_name= trim(prname) // "solver_data_mpi.bp" 
  call MPI_Comm_dup (MPI_COMM_WORLD, comm, ierr)

  call adios_read_init_method (ADIOS_READ_METHOD_BP, comm, &
      "verbose=1", adios_err)
  call check_adios_err(myrank,adios_err)
  call adios_read_open_file (adios_handle, file_name, 0, comm, ierr)
  call check_adios_err(myrank,adios_err)

  ! MPI interfaces
  call adios_get_scalar(adios_handle, "num_interfaces", &
      num_interfaces_crust_mantle, adios_err)

  allocate(my_neighbours_crust_mantle(num_interfaces_crust_mantle), &
          nibool_interfaces_crust_mantle(num_interfaces_crust_mantle), &
          stat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank, &
      'error allocating array my_neighbours_crust_mantle etc.')

  if( num_interfaces_crust_mantle > 0 ) then
    call adios_get_scalar(adios_handle, "max_nibool_interfaces", &
      max_nibool_interfaces_cm, adios_err)
    allocate(ibool_interfaces_crust_mantle(max_nibool_interfaces_cm, &
        num_interfaces_crust_mantle), stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank, &
        'error allocating array ibool_interfaces_crust_mantle')

    local_dim = num_interfaces_crust_mantle
    start(1) = local_dim*myrank; count(1) = local_dim
    call adios_selection_boundingbox (sel , 1, start, count)
    call adios_schedule_read(adios_handle, sel, "my_neighbours/array", 0, 1, &
      my_neighbours_crust_mantle, adios_err)
    call check_adios_err(myrank,adios_err)
    call adios_schedule_read(adios_handle, sel, "nibool_interfaces/array", &
      0, 1, nibool_interfaces_crust_mantle, adios_err)
    call check_adios_err(myrank,adios_err)

    call adios_perform_reads(adios_handle, adios_err)
    call check_adios_err(myrank,adios_err)

    local_dim = max_nibool_interfaces_cm * num_interfaces_crust_mantle
    start(1) = local_dim*myrank; count(1) = local_dim
    call adios_selection_boundingbox (sel , 1, start, count)
    call adios_schedule_read(adios_handle, sel, &
      "ibool_interfaces/array", 0, 1, &
      ibool_interfaces_crust_mantle, adios_err)
    call check_adios_err(myrank,adios_err)

    call adios_perform_reads(adios_handle, adios_err)
    call check_adios_err(myrank,adios_err)
  else
    ! dummy array
    max_nibool_interfaces_cm = 0
    allocate(ibool_interfaces_crust_mantle(0,0),stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank, &
        'error allocating array dummy ibool_interfaces_crust_mantle')
  endif

  ! inner / outer elements
  call adios_get_scalar(adios_handle, "nspec_inner", &
      nspec_inner_crust_mantle, adios_err)
  call adios_get_scalar(adios_handle, "nspec_outer", &
      nspec_outer_crust_mantle, adios_err)
  call adios_get_scalar(adios_handle, "num_phase_ispec", &
      num_phase_ispec_crust_mantle, adios_err)
  if( num_phase_ispec_crust_mantle < 0 ) &
      call exit_mpi(myrank,'error num_phase_ispec_crust_mantle is < zero')

  allocate(phase_ispec_inner_crust_mantle(num_phase_ispec_crust_mantle,2),&
          stat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank, &
      'error allocating array phase_ispec_inner_crust_mantle')

  if(num_phase_ispec_crust_mantle > 0 ) then
    local_dim = num_phase_ispec_crust_mantle * 2
    start(1) = local_dim*myrank; count(1) = local_dim
    call adios_selection_boundingbox (sel , 1, start, count)
    call adios_schedule_read(adios_handle, sel, &
      "phase_ispec_inner/array", 0, 1, &
      phase_ispec_inner_crust_mantle, adios_err)
    call check_adios_err(myrank,adios_err)

    call adios_perform_reads(adios_handle, adios_err)
    call check_adios_err(myrank,adios_err)
  endif

  ! mesh coloring for GPUs
  if( USE_MESH_COLORING_GPU ) then
    call adios_get_scalar(adios_handle, "num_colors_outer", &
        num_colors_outer_crust_mantle, adios_err)
    call adios_get_scalar(adios_handle, "num_colors_inner", &
        num_colors_inner_crust_mantle, adios_err)
    ! colors

    allocate(num_elem_colors_crust_mantle(num_colors_outer_crust_mantle +&
        num_colors_inner_crust_mantle), stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank,'error allocating num_elem_colors_crust_mantle array')

    local_dim = num_colors_outer_crust_mantle + num_colors_inner_crust_mantle 
    start(1) = local_dim*myrank; count(1) = local_dim
    call adios_selection_boundingbox (sel , 1, start, count)
    call adios_schedule_read(adios_handle, sel, &
      "num_elem_colors/array", 0, 1, &
      num_elem_colors_crust_mantle, adios_err)
    call check_adios_err(myrank,adios_err)

    call adios_perform_reads(adios_handle, adios_err)
    call check_adios_err(myrank,adios_err)
  else
    ! allocates dummy arrays
    num_colors_outer_crust_mantle = 0
    num_colors_inner_crust_mantle = 0
    allocate(num_elem_colors_crust_mantle(num_colors_outer_crust_mantle + &
        num_colors_inner_crust_mantle), stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank, &
          'error allocating num_elem_colors_crust_mantle array')
  endif
  ! Close ADIOS handler to the restart file.
  call adios_selection_delete(sel)
  call adios_read_close(adios_handle, adios_err)
  call check_adios_err(myrank,adios_err)
  call adios_read_finalize_method(ADIOS_READ_METHOD_BP, adios_err)
  call check_adios_err(myrank,adios_err)

  call MPI_Barrier(comm, ierr)

  end subroutine read_mesh_databases_MPI_CM_adios


!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_MPI_OC_adios()

  use specfem_par
  use specfem_par_outercore
  implicit none

  ! local parameters
  integer :: ierr

  ! crust mantle region

  ! create the name for the database of the current slide and region
  call create_name_database(prname,myrank,IREGION_OUTER_CORE,LOCAL_PATH)

  open(unit=IIN,file=prname(1:len_trim(prname))//'solver_data_mpi.bin', &
       status='old',action='read',form='unformatted',iostat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error opening solver_data_mpi.bin')

  ! MPI interfaces
  read(IIN) num_interfaces_outer_core
  allocate(my_neighbours_outer_core(num_interfaces_outer_core), &
          nibool_interfaces_outer_core(num_interfaces_outer_core), &
          stat=ierr)
  if( ierr /= 0 ) &
    call exit_mpi(myrank,'error allocating array my_neighbours_outer_core etc.')

  if( num_interfaces_outer_core > 0 ) then
    read(IIN) max_nibool_interfaces_oc
    allocate(ibool_interfaces_outer_core(max_nibool_interfaces_oc,num_interfaces_outer_core), &
            stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error allocating array ibool_interfaces_outer_core')

    read(IIN) my_neighbours_outer_core
    read(IIN) nibool_interfaces_outer_core
    read(IIN) ibool_interfaces_outer_core
  else
    ! dummy array
    max_nibool_interfaces_oc = 0
    allocate(ibool_interfaces_outer_core(0,0),stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error allocating array dummy ibool_interfaces_outer_core')
  endif

  ! inner / outer elements
  read(IIN) nspec_inner_outer_core,nspec_outer_outer_core
  read(IIN) num_phase_ispec_outer_core
  if( num_phase_ispec_outer_core < 0 ) &
    call exit_mpi(myrank,'error num_phase_ispec_outer_core is < zero')

  allocate(phase_ispec_inner_outer_core(num_phase_ispec_outer_core,2),&
          stat=ierr)
  if( ierr /= 0 ) &
    call exit_mpi(myrank,'error allocating array phase_ispec_inner_outer_core')

  if(num_phase_ispec_outer_core > 0 ) read(IIN) phase_ispec_inner_outer_core

  ! mesh coloring for GPUs
  if( USE_MESH_COLORING_GPU ) then
    ! colors
    read(IIN) num_colors_outer_outer_core,num_colors_inner_outer_core

    allocate(num_elem_colors_outer_core(num_colors_outer_outer_core + num_colors_inner_outer_core), &
            stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank,'error allocating num_elem_colors_outer_core array')

    read(IIN) num_elem_colors_outer_core
  else
    ! allocates dummy arrays
    num_colors_outer_outer_core = 0
    num_colors_inner_outer_core = 0
    allocate(num_elem_colors_outer_core(num_colors_outer_outer_core + num_colors_inner_outer_core), &
            stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank,'error allocating num_elem_colors_outer_core array')
  endif

  close(IIN)

  end subroutine read_mesh_databases_MPI_OC_adios

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_MPI_IC_adios()

  use specfem_par
  use specfem_par_innercore
  implicit none

  ! local parameters
  integer :: ierr

  ! crust mantle region

  ! create the name for the database of the current slide and region
  call create_name_database(prname,myrank,IREGION_INNER_CORE,LOCAL_PATH)

  open(unit=IIN,file=prname(1:len_trim(prname))//'solver_data_mpi.bin', &
       status='old',action='read',form='unformatted',iostat=ierr)
  if( ierr /= 0 ) call exit_mpi(myrank,'error opening solver_data_mpi.bin')

  ! MPI interfaces
  read(IIN) num_interfaces_inner_core
  allocate(my_neighbours_inner_core(num_interfaces_inner_core), &
          nibool_interfaces_inner_core(num_interfaces_inner_core), &
          stat=ierr)
  if( ierr /= 0 ) &
    call exit_mpi(myrank,'error allocating array my_neighbours_inner_core etc.')

  if( num_interfaces_inner_core > 0 ) then
    read(IIN) max_nibool_interfaces_ic
    allocate(ibool_interfaces_inner_core(max_nibool_interfaces_ic,num_interfaces_inner_core), &
            stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error allocating array ibool_interfaces_inner_core')

    read(IIN) my_neighbours_inner_core
    read(IIN) nibool_interfaces_inner_core
    read(IIN) ibool_interfaces_inner_core
  else
    ! dummy array
    max_nibool_interfaces_ic = 0
    allocate(ibool_interfaces_inner_core(0,0),stat=ierr)
    if( ierr /= 0 ) call exit_mpi(myrank,'error allocating array dummy ibool_interfaces_inner_core')
  endif

  ! inner / outer elements
  read(IIN) nspec_inner_inner_core,nspec_outer_inner_core
  read(IIN) num_phase_ispec_inner_core
  if( num_phase_ispec_inner_core < 0 ) &
    call exit_mpi(myrank,'error num_phase_ispec_inner_core is < zero')

  allocate(phase_ispec_inner_inner_core(num_phase_ispec_inner_core,2),&
          stat=ierr)
  if( ierr /= 0 ) &
    call exit_mpi(myrank,'error allocating array phase_ispec_inner_inner_core')

  if(num_phase_ispec_inner_core > 0 ) read(IIN) phase_ispec_inner_inner_core

  ! mesh coloring for GPUs
  if( USE_MESH_COLORING_GPU ) then
    ! colors
    read(IIN) num_colors_outer_inner_core,num_colors_inner_inner_core

    allocate(num_elem_colors_inner_core(num_colors_outer_inner_core + num_colors_inner_inner_core), &
            stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank,'error allocating num_elem_colors_inner_core array')

    read(IIN) num_elem_colors_inner_core
  else
    ! allocates dummy arrays
    num_colors_outer_inner_core = 0
    num_colors_inner_inner_core = 0
    allocate(num_elem_colors_inner_core(num_colors_outer_inner_core + num_colors_inner_inner_core), &
            stat=ierr)
    if( ierr /= 0 ) &
      call exit_mpi(myrank,'error allocating num_elem_colors_inner_core array')
  endif

  close(IIN)

  end subroutine read_mesh_databases_MPI_IC_adios


!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_mesh_databases_stacey_adios()

  use specfem_par
  use specfem_par_crustmantle
  use specfem_par_innercore
  use specfem_par_outercore

  implicit none

  ! local parameters
  integer :: ierr

  ! crust and mantle

  ! create name of database
  call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

  ! read arrays for Stacey conditions
  open(unit=27,file=prname(1:len_trim(prname))//'stacey.bin', &
        status='old',form='unformatted',action='read',iostat=ierr)
  if( ierr /= 0 ) call exit_MPI(myrank,'error opening stacey.bin file for crust mantle')

  read(27) nimin_crust_mantle
  read(27) nimax_crust_mantle
  read(27) njmin_crust_mantle
  read(27) njmax_crust_mantle
  read(27) nkmin_xi_crust_mantle
  read(27) nkmin_eta_crust_mantle
  close(27)

  ! outer core

  ! create name of database
  call create_name_database(prname,myrank,IREGION_OUTER_CORE,LOCAL_PATH)

  ! read arrays for Stacey conditions
  open(unit=27,file=prname(1:len_trim(prname))//'stacey.bin', &
        status='old',form='unformatted',action='read',iostat=ierr)
  if( ierr /= 0 ) call exit_MPI(myrank,'error opening stacey.bin file for outer core')

  read(27) nimin_outer_core
  read(27) nimax_outer_core
  read(27) njmin_outer_core
  read(27) njmax_outer_core
  read(27) nkmin_xi_outer_core
  read(27) nkmin_eta_outer_core
  close(27)

  end subroutine read_mesh_databases_stacey_adios

