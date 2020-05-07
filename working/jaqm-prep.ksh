#!/bin/ksh -x
#BSUB -o jaqm_prep_5x.out
#BSUB -e jaqm_prep_5x.err
#BSUB -J aqm_prep_5x
#BSUB -W 00:30
#BSUB -q debug
#BSUB -P CMAQ-T2O
##BSUB -extsched "CRAYLINUX[]" -R "1*{select[craylinux && !vnode]} + 576*{select[craylinux && vnode] span [ptile=24]}"
#BSUB -M 3000
#BSUB -extsched 'CRAYLINUX[]'
#BSUB -cwd .

#if [ $cyc -eq 06 -o $cyc -eq 12 ]; then
 export NODES=10
#else
# export NODES=1
#fi  

export job=${job:-$LSB_JOBNAME}
export jobid=${jobid:-$job.$LSB_JOBID}
export RUN_ENVIR=${RUN_ENVIR:-aqm}
export envir=${envir:-para}
export SENDDBN=${SENDDBN:-YES}
export SENDDBN_NTC=${SENDDBN_NTC:-YES}

source /opt/modules/default/init/ksh
module load PrgEnv-intel
module load cray-netcdf/4.3.2
module load cray-hdf5/1.8.13
module load cray-mpich/7.2.0
module load prod_util
module load prod_envir
module load grib_util/1.0.3

export KEEPDATA=YES

export IOBUF_PARAMS="*:verbose:size=16M:count=4"

# EXPORT list here
set -ax
export PARAFLAG=YES

export FCST=YES

${HOMEaqm}/jobs/JAQM_PREP_CS
