#!/bin/ksh -xa

#source ~/.bashrc

#source /opt/modules/default/init/ksh
OUTGRIB=0

module load prod_util

export NDATE=${NDATE:-/gpfs/hps/nco/ops/nwprod/prod_util.v1.0.29/exec/ndate}


machine=`hostname | cut -c1`

if [ $machine = s ]
then
  machine='g'
else
  machine='t'
fi

export cyc=12
export CYC=$cyc
cycle=t${cyc}z
export SINGLECYC=YES # one cycle run

today=`$NDATE`

export FRPRATIO=1.0

export HOMEaqm=/gpfs/hps3/emc/naqfc/noscrub/Youhua.Tang/nwdev/NAQFC-WCOSS
export EXECaqm=$HOMEaqm/exec
export cmaq_ver=v5.3.1
export usrdir=/gpfs/hps3/emc/naqfc/noscrub/${USER}
export usr_tmp=/gpfs/hps3/ptmp/${USER}
export envir=para
export model=cmaq
export RUN=aqm
export NET=aqm

export PDY=${1:-`$NDATE -24 $today|cut -c1-8`}
export END_PDY=${2:-$PDY}

while [ $PDY -le $END_PDY ]; do

MYPARA9=$usr_tmp/com/aqm/para

export PDYm1=`$NDATE -24 ${PDY}${cyc} | cut -c1-8`
export PDYm2=`$NDATE -48 ${PDY}${cyc} | cut -c1-8`
export PDYm3=`$NDATE -72 ${PDY}${cyc} | cut -c1-8`

export PDYp1=`$NDATE +24 ${PDY}${cyc} | cut -c1-8`
export PDYp2=`$NDATE +48 ${PDY}${cyc} | cut -c1-8`
export PDYp3=`$NDATE +72 ${PDY}${cyc} | cut -c1-8`
 
export COMOUT=${usr_tmp}/com/aqm/${envir}/${RUN}.${PDY}
if [ ! -s $COMOUT ]; then
mkdir -p $COMOUT
fi

export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`

if [ ! -s $COMOUT/aqm.t$cycle.metcro3d.ncf ] || [ ! -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] \
 || [ ! -s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf ] ; then
# Prep
export pid=`od -An -N2 -i /dev/random | sed 's/^[ \t]*//'`
export job=aqm_prep_cs
export DATA=${usr_tmp}/tmpnwprd/${job}.$pid
export jlogfile=${usr_tmp}/com/logs/jlogfiles/jlogfile.$pid

export FCST=YES  # for forecast or "NO" for analysis
export COMIN=$COMOUT
export FV3CHEMFOLDER=$COMIN
export InMetDir=$COMIN
if [ ! -s $InMetDir/gfs.$cycle.atmf072.nc ] && [ ! -s $COMOUT/aqm.t$cycle.metcro3d.ncf ] ; then
hsi<<!
lcd $COMIN
cd /NCEPDEV/emc-naqfc/2year/Youhua.Tang/fv3-out/$PDY
get gfs.$cycle.atmf0??.nc
get gfs.$cycle.sfcf0??.nc
bye
!
fi

if [ ! -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] && [ ! -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDY.nc ]\
 && [ ! -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
 if [ -s /gpfs/dell1/nco/ops/dcom/dev/$PDYp1/firewx/GBBEPx_all01GRID.emissions_v003_$PDY.nc ]; then
  ln -s /gpfs/dell1/nco/ops/dcom/dev/$PDYp1/firewx/GBBEPx_all01GRID.emissions_v003_$PDY.nc $COMIN
 elif [ -s /gpfs/dell1/nco/ops/dcom/dev/$PDY/firewx/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
  ln -s /gpfs/dell1/nco/ops/dcom/dev/$PDY/firewx/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc $COMIN
 else
  echo " can not find GBBEPX emission"
  exit 1
 fi
fi
   
bsub< $HOMEaqm/working/jaqm-prep.ksh

 ic=0
 while [ $ic -le 40 ]; do
  if [ -s $COMOUT/aqm.$cycle.metcro3d.ncf ] && [ -s $COMOUT/aqm.$cycle.fire_emi_cs.ncf ] \
   && [ -s $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf ] ; then
   break
  else
   let ic=ic+1
   sleep 10
  fi
 done  
 if [ $ic -gt 40 ]; then
   err_exit *****FATAL ERROR***** - COULD NOT LOCATE: $COMOUT/aqm.$cycle.metcro3d.ncf\
   $COMOUT/aqm.$cycle.fire_location_cs.ncf $COMOUT/aqm_conus_geos_fv3chem_aero_${PDY}_35L.ncf
 fi

fi

## CMAQ forecast
if [ ! -s $COMOUT/aqm.t${cyc}z.conc.ncf ]; then

export FIXaqm=$HOMEaqm/fix
export COMROOT=${usr_tmp}/com
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
if [ ! -s ${COMROOT}/logs ]; then
 mkdir -p ${COMROOT}/logs
fi 
if [ ! -s $DATA ]; then
 mkdir -p $DATA
fi
cd $DATA 
bsub < ${HOMEaqm}/working/jaqm_fcst_cs.ksh
err=$?
if [ ${err} -ne 0 ]; then
  echo "FATAL - cmaq fcst failed with error code ${err}"
  exit 101
fi
exit

rm -f log.grep
while [ ! -s log.grep ]; do
 if [ -s jaqm_aot_nlbc.out ]; then
  tail -2000 jaqm_aot_nlbc.out | grep "Program completed successfully" > log.grep
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

cd $COMOUT  
$HOME/bin/csum -rf 1 -sl ${HOMEaqm}/vlist.twoways.5.0.2.my aqm.t${cyc}z.conc.ncf aqm.t${cyc}z.aerodiam.ncf \
   aqm.t${cyc}z.metcro3d.ncf aqm.$PDY.t${cyc}z.aconc-pm25.ncf

$HOMEaqm/AOD_via_VIS2.x aqm.t${cyc}z.metcro3d.ncf aqm.t${cyc}z.vis.ncf aqm.$PDY.t${cyc}z.aod.ncf

# scp -p $COMOUT/aqm.$PDY.t${cyc}z.*.ncf youhuat@byun.arl.noaa.gov:/data/aqf/youhuat/cmaq5.0.2-72hr-fast
# ${HOMEaqm}/hsi-1.ksh $COMOUT 72hour-test/fv3-cmaq-fast.$PDY $cyc &
scp -p $COMOUT/aqm.$PDY.t${cyc}z.*.ncf youhuat@byun.arl.noaa.gov:/data/aqf3/youhuat/aot-nlbc-gbbepxb

# $HOMEaqm/working/for-ucla2.ksh &

cat>hsi-select.ksh<<EOF
#!/bin/ksh -x
hsi<<!
mkdir /5year/NCEPDEV/emc-naqfc/Youhua.Tang/72hour-test/aot-nlbc-gbbepxb.$PDY
cd /5year/NCEPDEV/emc-naqfc/Youhua.Tang/72hour-test/aot-nlbc-gbbepxb.$PDY
put aqm*t${cyc}z.aod.ncf
put aqm*t${cyc}z.cgrid.ncf
put aqm*t${cyc}z.vis.ncf
put aqm*t${cyc}z.aerodiam.ncf
put aqm*soil*ncf
put aqm*t${cyc}z.*conc*.ncf
put *ptfire*ncf
bye
!
EOF
chmod +x hsi-select.ksh
./hsi-select.ksh &
fi

if [ $OUTGRIB -eq 1 ]; then
 COMOUT=/gpfs/${machine}d2/emc/naqfc/noscrub/Youhua.Tang/grib2-aot-nlbc-gbbepxb/$PDY
 if [ ! -s $COMOUT ]; then
 mkdir -p $COMOUT
 fi

execfile=/gpfs/hps/nco/ops/nwprod/cmaq.v5.0.3/exec/aqm_cmaq2grib2_v2
execfile2=/gpfs/hps/nco/ops/nwprod/cmaq.v5.0.3/exec/aqm_post_maxi_CHA_grib2_v2
WGRIB2=$HOME/bin/wgrib2

export CHEM3D=$COMIN/aqm.$PDY.$cycle.aconc-pm25.ncf
 
if [ ! -s $COMOUT/aqm.${cycle}.awpozcon.f01.148.grib2 ]; then
cat >cmaq2grib2.ini <<EOF5
&control
varlist='O3','O3_8hr'
metlist='  '
outfile='$COMOUT/aqm.${cycle}.awpozcon'
ozonecatfile='$COMOUT/aqm.${cycle}.awpozcat'
nlayers=1
id_gribdomain=148
ave1hr=.true.
/
EOF5
$execfile
fi

if [ ! -s $COMOUT/aqm.${cycle}.pm25.f01.148.grib2 ]; then
cat >cmaq2grib2.ini <<EOF5
&control
varlist='PM2.5'
metlist='  '
outfile='$COMOUT/aqm.${cycle}.pm25'
nlayers=1
id_gribdomain=148
ave1hr=.true.
/
EOF5
$execfile
fi

export CMAQFILE1=$CHEM3D
if [ -s $COMINm1/aqm.$PDYm1.$cycle.aconc-pm25.ncf ]; then
 export CMAQFILE2=$COMINm1/aqm.$PDYm1.$cycle.aconc-pm25.ncf  
elif [ -s $COMINm2/aqm.$PDYm2.$cycle.aconc-pm25.ncf ]; then
 export CMAQFILE2=$COMINm2/aqm.$PDYm2.$cycle.aconc-pm25.ncf
else
 export CMAQFILE2=$CMAQFILE1
fi
export CMAQFILE3=$CMAQFILE2

if [ ! -s $COMOUT/aqm.${cycle}.max_1hr_o3.148.grib2 ]; then

rm -f aqm-maxi.148.grib2
cat >cmaq-maxi2grib.ini <<EOF5
&control
markutc=05
outfile='aqm-maxi.148.grib2'
varlist='o3_1hr','o3_8hr'
id_gribdomain=148
/
EOF5

$execfile2

$WGRIB2 aqm-maxi.148.grib2 |grep "OZMAX1" | $WGRIB2 -i aqm-maxi.148.grib2 -grib  $COMOUT/aqm.${cycle}.max_1hr_o3.148.grib2
$WGRIB2 aqm-maxi.148.grib2 |grep "OZMAX8" | $WGRIB2 -i aqm-maxi.148.grib2 -grib  $COMOUT/aqm.${cycle}.max_8hr_o3.148.grib2

fi

if [ ! -s $COMOUT/aqm.${cycle}.max_1hr_pm25.148.grib2 ]; then
rm -f aqm-pm25_24hr.148.grib2
cat >cmaq-maxi2grib.ini <<EOF5
&control
markutc=05
outfile='aqm-pm25_24hr.148.grib2'
varlist='pm25_1hr','pm25_24hr'
id_gribdomain=148
/
EOF5
$execfile2

$WGRIB2 aqm-pm25_24hr.148.grib2 |grep "PDMAX1" | $WGRIB2 -i aqm-pm25_24hr.148.grib2 -grib $COMOUT/aqm.${cycle}.max_1hr_pm25.148.grib2
$WGRIB2 aqm-pm25_24hr.148.grib2 |grep "PMTF" | $WGRIB2 -i aqm-pm25_24hr.148.grib2 -grib  $COMOUT/aqm.${cycle}.ave_24hr_pm25.148.grib2
fi

if [ -s $COMOUT/aqm.${cycle}.pm25.f01.148.grib2 ]; then
hsi<<EOF
cd emc-naqfc/5year/Youhua.Tang/72hour-test/aot-nlbc-gbbepxb.$PDY
lcd $COMOUT
!tar czvf aqm.$PDY.t${cyc}z.grib2.tgz *.grib2
put aqm.$PDY.t${cyc}z.grib2.tgz
bye
EOF
fi

fi  # OUTGRIB

export PDY=`$NDATE +24 ${PDY}${cyc} | cut -c1-8`
done
