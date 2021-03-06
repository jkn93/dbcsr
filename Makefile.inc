
#######################################################################################
#
# DBCSR can be compiled in 4 main variants:
# 1) Serial, i.e. no OpenMP and MPI
# 2) OpenMP
# 3) MPI
# 4) OpenMP+MPI
#
# Except the 1) variant (not useful for real production cases), all others are tested.
# Variants 2) and 4) requires to add the compiler flag to enable OpenMP, 
# e.g. -fopenmp for GNU and Intel compilers.
# Variants 3) and 4) requires to use MPI wrappers for the compilation and to specify
# -D__parallel in the FCFLAGS variable.
#
# The 4 variants can be combined with the CUDA compilation. In this case, it further 
# requires:
# a) set the NVCC variable, e.g. NVCC = nvcc
# b) specify -D__DBCSR_ACC in FCFLAGS variable
# c) set the GPUVER variable, e.g. GPUVER = K20 for K20 card 
#    or GPUVER = P100 for P100 card
# d) set the NVFLAGS variable, 
#    e.g. NVFLAGS = -O3 -g -w --std=c++11
#    in the Makefile, the -arch will be appended with the correct compute version
# e) specify the CUDA include path in the CXXFLAGS variable, 
#    e.g. CXXFLAGS += -I${CUDA_PATH}/include 
# f) specify the corresponding CUDA libraries in the LIBS variable,
#    e.g. LIBS += -lstdc++ -lcudart -lnvrtc -lcuda
#
# Below we present an example for OpenMP+MPI compilation for the GNU compiler.
# Make sure that the env variable $LAPACK_PATH is set.
#
# GPU compilation example can be enabled with `make GPU=1`.
# Make sure that the env variable ${CUDA_PATH} is set.
#

#######################################################################################
#
# Optional configuration:
#
# *** LIBXSMM ***
#
# Performance of the library can be improved on the CPU execution by using
# the libxsmm, a library for small matrix multiplications which 
# is provided by Intel: https://github.com/hfp/libxsmm/.
# Provide LIBXSMM_DIR or adjust the FCFLAGS variable e.g.,
# FCFLAGS += -I${LIBXSMM_DIR}/include -D__LIBXSMM
# and specify the library in the LIBS variable, e.g.
# LIBS += -L${LIBXSMM_DIR}/lib -lxsmmf -lxsmm -ldl

ifneq (,$(LIBXSMM_DIR))
  FCFLAGS += -I${LIBXSMM_DIR}/include -D__LIBXSMM
  LIBS += -L${LIBXSMM_DIR}/lib -lxsmmf -lxsmm -ldl
endif

#######################################################################################
#
# Optional configuration:
#
# *** CUBLAS ***
#
# For multiplications of dense matrices, it can be beneficial to "densify" the matrices 
# and then use DGEMM for the local multiplication. This is the default behavior for the
# CPU execution, while it requires to link CUBLAS for the GPU execution 
# (LIBS += -lcublas) and to specify the macro -D__DBCSR_ACC=2 in the FCFLAGS and NVFLAGS
# variables.
#

#######################################################################################
#
# Variables for the commands:
# CC  => C compiler, e.g. gcc or mpicc
# CXX => C++ compiler, e.g. g++ or mpicxx
# FC  => Fortran compiler, e.g. gfortran or mpifort
# LD  => Linker, e.g. gfortran or mpifort
# AR  => Archive command, e.g. ar -r

ifneq (0,$(MPI))
  ifneq (0,$(GNU)) # DEFAULT, just edit...
    CXX = mpicxx
    CC  = mpigcc
    FC  = mpif90
    LD  = mpif90
    AR  = gcc-ar -r
    # flags
    CXXFLAGS += -std=c++11
    FCFLAGS  += -fopenmp -ffree-form -fimplicit-none -ffree-line-length-512
    OPTFLAGS += -O3 -g -fno-omit-frame-pointer -funroll-loops
  else
    CXX = mpiicpc
    CC  = mpiicc
    FC  = mpiifort
    LD  = mpiifort
    AR  = xiar -r
    # flags
    CXXFLAGS += -std=c++11
    FCFLAGS  += -fopenmp -free
    OPTFLAGS += -O2 -g
  endif
else # no MPI
  CXX = g++
  CC  = gcc
  FC  = gfortran
  LD  = gfortran
  AR  = ar -r
  # flags
  CXXFLAGS += -std=c++11
  FCFLAGS  += -fopenmp -std=f2003 -ffree-form -fimplicit-none -ffree-line-length-512
  OPTFLAGS += -O3 -g -fno-omit-frame-pointer -funroll-loops
endif

#######################################################################################
#
# Corresponding command flags.
# Note the -fopenmp flag to have OpenMP parallelization.

OPTFLAGS    += 
CFLAGS      += $(OPTFLAGS)
CXXFLAGS    += $(OPTFLAGS)
FCFLAGS     += $(OPTFLAGS)
LDFLAGS     += $(FCFLAGS)

#######################################################################################
#
# C interface requires new F2008ts standard

ifneq ($(CINT),)
FCFLAGS    := $(subst -std=f2003,-std=f2008ts,$(FCFLAGS))
endif

#######################################################################################
#
# Macro for MPI parallelization.

ifneq (0,$(MPI))
FCFLAGS += -D__parallel
endif

#######################################################################################
#
# Minimal external libraries, i.e. BLAS and LAPACK.

LIBS        = -L${LAPACK_PATH}/lib -llapack -lblas

#######################################################################################
#
# GPU compilation. Use `make GPU=1` to enable it.

ifneq ($(GPU),)
NVCC        = nvcc
FCFLAGS    += -D__DBCSR_ACC
GPUVER      = K40
NVFLAGS     = -O3 -g -w --std=c++11
CXXFLAGS   += -I${CUDA_PATH}/include
LIBS       += -lstdc++ -lcudart -lnvrtc -lcuda
# CUBLAS (off by default)
#FCFLAGS    := $(subst -D__DBCSR_ACC,-D__DBCSR_ACC=2,$(FCFLAGS))
#NVFLAGS    += -D__DBCSR_ACC=2
#LIBS       += -lcublas
endif

#######################################################################################
#
# Optional flags for warnings and checks.
# We do not simply use -Wall since some warnings for Fortran are misleading.
# For the checks use `make CHECKS=1` to enable them.

ifneq (0,$(GNU))
WFLAGS      = -Werror=aliasing -Werror=ampersand -Werror=c-binding-type \
              -Werror=intrinsic-shadow -Werror=intrinsics-std \
              -Werror=line-truncation \
              -Werror=tabs -Werror=realloc-lhs-all -Werror=target-lifetime \
              -Werror=underflow \
              -Werror=unused-but-set-variable -Werror=unused-variable \
              -Werror=unused-dummy-argument -Werror=conversion
              -Werror=zerotrip \
              -Werror=uninitialized -Wno-maybe-uninitialized -Wuse-without-only \
              -Werror
endif

FCFLAGS    += $(WFLAGS)

ifneq ($(CHECKS),)
FCFLAGS    += -fsanitize=leak
FCFLAGS    += -fcheck=bounds,do,recursion,pointer -Wconversion -fbacktrace
endif

#######################################################################################
