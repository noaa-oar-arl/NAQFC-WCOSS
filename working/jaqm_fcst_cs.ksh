#!/bin/ksh
#BSUB -J jaqm_fcst_v531_cs 
#BSUB -o jaqm_fcst_cs.out 
#BSUB -e jaqm_fcst_cs.err 
#BSUB -q dev 
##BSUB -q debug 
#BSUB -M 3000
#BSUB -W 02:30
#BSUB -P CMAQ-T2O 
#BSUB -cwd .
#BSUB -extsched 'CRAYLINUX[]'

#%include <head.h>
#%include <envir-xc40.h>
#
source /opt/modules/default/init/ksh 
module unload PrgEnv-cray
module load PrgEnv-intel
module load iobuf
module load prod_util
module load prod_envir

export NODES=24
export IOBUF_PARAMS="12M:verbose"

set -ax

ulimit -s unlimited

export RUN_ENVIR=notnco
export COMROOT=/gpfs/hps3/ptmp/${USER}/com
export NWROOT=/u/${USER}/noscrub/nwdev
export NWROOTp1=/nwprod
export cmaq_ver=v5.3.1
export envir=para
export job=aqm_cmaq_cs
#
export PARAFLAG=YES

export SENDCOM=YES
export SENDDBN=NO
export SENDECF=NO

export FCST=YES
 
${HOMEaqm}/jobs/JAQM_FORECAST_CS

err=$?
if [ "${PARAFLAG}" = "YES" ]
then
  if [ ${err} -ne 0 ]
  then
    exit 249
  fi
fi
