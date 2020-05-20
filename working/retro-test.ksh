#!/bin/ksh -xa

module load prod_util
module load prod_envir

machine=`hostname | cut -c1`

SAVEHPSS=NO

set -x

export cyc=12
export CYC=$cyc
cycle=t${cyc}z
export SINGLECYC=YES # one cycle run
export FCST=YES  # for forecast or "NO" for analysis

today=`$NDATE`
## hardwire date for now
today=2019071512

export FRPRATIO=1.0

BASE=`pwd`
export HOMEaqm="$(dirname ${BASE})"
export NWROOT=="$(dirname ${HOMEaqm})"

export EXECaqm=$HOMEaqm/exec
export cmaq_ver=v5.3.1
export usrdir=/gpfs/hps3/emc/naqfc/noscrub/${USER}
export usr_tmp=/gpfs/hps3/ptmp/${USER}
export envir=para6
export model=cmaq
export RUN=aqm
export NET=aqm
## export FIXaqm=$HOMEaqm/fix
export FIXaqm=/gpfs/hps3/emc/naqfc/noscrub/Ho-Chun.Huang/nwpara/AQMv6_COM_FIX

export COMROOT=${usr_tmp}/com

export PDY=${1:-`$NDATE -24 $today|cut -c1-8`}
export END_PDY=${2:-$PDY}

while [ $PDY -le $END_PDY ]; do

export PDYm1=`$NDATE -24 ${PDY}${cyc} | cut -c1-8`
export PDYm2=`$NDATE -48 ${PDY}${cyc} | cut -c1-8`
export PDYm3=`$NDATE -72 ${PDY}${cyc} | cut -c1-8`

export PDYp1=`$NDATE +24 ${PDY}${cyc} | cut -c1-8`
export PDYp2=`$NDATE +48 ${PDY}${cyc} | cut -c1-8`
export PDYp3=`$NDATE +72 ${PDY}${cyc} | cut -c1-8`
 
export COMOUT=${usr_tmp}/com/aqm/${envir}/${RUN}.${PDY}
mkdir -p $COMOUT

export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`

if [ ! -s $COMOUT/aqm.$cycle.metcro3d.ncf ] || [ ! -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] \
 || [ ! -s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf ] ; then
# Prep
export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`
export job=aqm_prep_cs
export DATA=${usr_tmp}/tmpnwprd/${job}.$pid
export jlogfile=${usr_tmp}/com/logs/jlogfiles/jlogfile.$pid
mkdir -p ${usr_tmp}/com/logs/jlogfiles

export COMIN=$COMOUT
export COMINm1=${usr_tmp}/com/aqm/${envir}/${RUN}.${PDYm1}
export FV3CHEMFOLDER=$COMIN
export FV3CHEM_DIR=$FV3CHEMFOLDER
export InMetDir=$COMIN
if [ ! -s $InMetDir/gfs.$cycle.atmf072.nc ] && [ ! -s $COMOUT/aqm.$cycle.metcro3d.ncf ] ; then
 if [ $PDY -le 20190728 ]; then
 hsi<<EOF
 lcd $COMIN
 cd /NCEPDEV/emc-naqfc/2year/Youhua.Tang/fv3-out/$PDY-${cyc}z
 get gfs.$cycle.atmf0??.nc
 get gfs.$cycle.sfcf0??.nc
 bye
EOF
else
 hsi<<EOF
 lcd $COMIN
 cd /NCEPDEV/emc-global/2year/emc.glopara/WCOSS_D/gfsv16/fv3cmaq/$PDY$cyc
 get gfs_netcdfb?.tar
 !tar xvf gfs_netcdfb1.tar
 !tar xvf gfs_netcdfb2.tar
 !tar xvf gfs_netcdfb3.tar
bye
EOF
fi
if [ ! -s $InMetDir/gfs.$cycle.atmf072.nc ]; then
 echo " can not find $InMetDir/gfs.$cycle.atmf072.nc "
 exit 1
fi
fi
# check GBBEPX fire emission 
if [ ! -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] && [ ! -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDY.nc ]\
 && [ ! -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
 if [ -s /gpfs/dell1/nco/ops/dcom/dev/$PDYp1/firewx/GBBEPx_all01GRID.emissions_v003_$PDY.nc ]; then
  ln -s /gpfs/dell1/nco/ops/dcom/dev/$PDYp1/firewx/GBBEPx_all01GRID.emissions_v003_$PDY.nc $COMIN
 elif [ -s /gpfs/dell1/nco/ops/dcom/dev/$PDY/firewx/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
  ln -s /gpfs/dell1/nco/ops/dcom/dev/$PDY/firewx/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc $COMIN
 else
  hsi<<EOF
  lcd $COMIN
  cd /NCEPDEV/emc-naqfc/5year/Youhua.Tang/72hour-test/fv3-cmaq-gbbepx1.$PDY
  get GBBEPx_addVIIRS.emisX.001.$PDY.nc
  bye
EOF
  if [ -s $COMIN/GBBEPx_addVIIRS.emisX.001.$PDY.nc ]; then
   mv $COMIN/GBBEPx_addVIIRS.emisX.001.$PDY.nc $COMIN/GBBEPx_all01GRID.emissions_v003_$PDY.nc
  else  
   echo " can not find GBBEPX emission"
   exit 1
  fi 
 fi
fi

# check GEFS LBC input 
if [ ! -s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf ] && \
  [ ! -s $FV3CHEMFOLDER/gfs.t00z.atmf096.nemsio ]; then
 cd $COMIN 
 hpsstar get /NCEPDEV/emc-naqfc/2year/Li.Pan/GSDCHEM/ms088/gfs.$PDY.htar gfs.$PDY/00/gfs.t00z.atmf???.nemsio
 if [ -s gfs.$PDY/00/gfs.t00z.atmf096.nemsio ]; then
  ln -s gfs.$PDY/00/gfs.t00z.atmf???.nemsio .
 else
  echo "can not find GEFS aerosol files"
  exit 1
 fi
fi
cd $COMIN
rm -f jaqm_prep_5x.err  jaqm_prep_5x.out 
bsub< $HOMEaqm/working/jaqm-prep.ksh

 ic=0
 while [ $ic -le 100 ]; do
  if [ -s $COMOUT/aqm.$cycle.metcro3d.ncf ] && [ -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] \
   && [ -s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf ] ; then
   if [ `stat -c %s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf` -lt 160000000 ]; then
    let ic=ic+1
    sleep 20
   else 
    break
   fi 
  else
   let ic=ic+1
   sleep 20
  fi
 done  
 if [ $ic -gt 100 ]; then
   echo " *****FATAL ERROR***** - COULD NOT LOCATE: $COMOUT/aqm.$cycle.metcro3d.ncf\
   $COMOUT/aqm.$cycle.fire_location_cs.ncf $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf"
   exit 1   
 fi

fi

## CMAQ forecast
if [ ! -s $COMOUT/aqm.t${cyc}z.conc.ncf ]; then

export COMIN=$COMROOT/aqm/$envir/${RUN}.${PDY}
export COMINm1=$COMROOT/aqm/$envir/${RUN}.${PDYm1}
export COMINm2=$COMROOT/aqm/$envir/${RUN}.${PDYm2}
export COMINm3=$COMROOT/aqm/$envir/${RUN}.${PDYm3}
 
 if [ $cyc -eq 12 ]; then
 if [ ! -s $COMIN/aqm.t06z.cgrid_r.ncf ]; then
   if [ -s $COMINm1/aqm.t${cyc}z.cgrid.ncf ]; then
    echo "use $COMINm1/aqm.t${cyc}z.cgrid.ncf as initial condition"
   elif [ -s $COMINm2/aqm.t${cyc}z.cgrid.ncf ]; then 
    echo "use $COMINm2/aqm.t${cyc}z.cgrid.ncf as initial condition"
   elif [ -s $COMINm3/aqm.t${cyc}z.cgrid.ncf ]; then
    echo "use $COMINm3/aqm.t${cyc}z.cgrid.ncf as initial condition"
   else
    echo "can not find proper initial condition"
    exit 1
   fi
 fi
 fi

yyyymm=`echo $PDY|cut -c1-6`
export EMISpath=/gpfs/hps3/emc/naqfc/noscrub/Youhua.Tang/emission/nei2016v1/$yyyymm
export job=aqm_cmaq_cs
export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`
export DATA=${usr_tmp}/tmpnwprd/${job}.$pid #define working directory
export jlogfile=${COMROOT}/logs/jlogfile.${pid}
mkdir -p ${COMROOT}/logs
mkdir -p $DATA
cd $DATA 
bsub < ${HOMEaqm}/working/jaqm_fcst_cs.ksh
err=$?
if [ ${err} -ne 0 ]; then
  echo "FATAL - cmaq fcst failed with error code ${err}"
  exit 101
fi

rm -f log.grep
while [ ! -s log.grep ]; do
 if [ -s jaqm_fcst_cs.out ]; then
  tail -2000 jaqm_fcst_cs.out | grep "Successfully completed" > log.grep
 else
  sleep 60
 fi
 sleep 60
done

if [ ! -s $COMOUT/aqm.t${cyc}z.conc.ncf ]; then
 echo "cmaq run failed"
 exit 1
fi 
aline=`ncdump -h $COMOUT/aqm.t${cyc}z.conc.ncf |grep "TSTEP = UNLIMITED" |grep 73`
if [[ $aline = *73* ]]; then
 echo "CMAQ run succesfully"
else
 echo "cmaq run failed"
 exit 1
fi

fi

# POST
module load PrgEnv-intel
module load cray-netcdf/4.3.2
module load cray-hdf5/1.8.13
module load cray-mpich/7.2.0
module load nemsio-intel/2.2.2
module load nemsiogfs-intel
module load bacio-intel/2.0.1
module load w3emc-intel/2.2.0  w3nco-intel/2.0.6
module load jasper-gnu-haswell/1.900.1
module load png-intel-sandybridge
module use /gpfs/hps/nco/ops/nwtest/lib/modulefiles
module load g2-intel/3.1.0
if [ ! -s $COMOUT/aqm.$cycle.aconc_sfc.ncf ]; then
export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`
export DATA=${usr_tmp}/tmpnwprd/aqm_post1.$pid #define working directory
$HOMEaqm/jobs/JAQM_POST1_CS


if [ $SAVEHPSS = YES ]; then

cd $COMOUT
scp -p aqm.$cycle.aconc_sfc.ncf youhuat@aaqest.arl.noaa.gov:/data/aqf3/youhuat/cmaq531-test/aqm.$PDY.$cycle.aconc_sfc.ncf &
scp -p aqm.$cycle.rj_1.ncf youhuat@aaqest.arl.noaa.gov:/data/aqf3/youhuat/cmaq531-test/aqm.$PDY.$cycle.rj_1.ncf &

cat>hsi-select.ksh<<EOF
#!/bin/ksh -x
hsi<<!
mkdir /5year/NCEPDEV/emc-naqfc/Youhua.Tang/cmaq531-test/aqm.$PDY
cd /5year/NCEPDEV/emc-naqfc/Youhua.Tang/cmaq531-test/aqm.$PDY
put aqm*t${cyc}z.met*ncf
put aqm*t${cyc}z.cgrid.ncf
put aqm*t${cyc}z.rj_1.ncf
put aqm*t${cyc}z.pmdiag.ncf
put aqm*soil*ncf
put aqm*lufraccro*ncf
put aqm*fire*ncf
put aqm*t${cyc}z.*conc*.ncf
bye
!
EOF
chmod +x hsi-select.ksh
./hsi-select.ksh &
fi
fi
# delete the big GFS files
cd $COMIN
rm gfs*.nc gfs.$PDY/00/*.nemsio
export PDY=`$NDATE +24 ${PDY}${cyc} | cut -c1-8`
done
