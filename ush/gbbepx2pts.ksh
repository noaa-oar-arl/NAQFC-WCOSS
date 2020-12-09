#!/bin/ksh -x

if [ $FCST = "NO" ] ; then
 if [ -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
  FIREDATE=$PDYm1
  emisfile=GBBEPx_all01GRID.emissions_v003_$PDYm1.nc
  COMIN9=$COMIN
 elif [ -s $COMINm1/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
  FIREDATE=$PDYm1
  emisfile=GBBEPx_all01GRID.emissions_v003_$PDYm1.nc
  COMIN9=$COMINm1
  echo "WARNING GBBEPx_all01GRID.emissions_v003_$PDYm1.nc found in $COMINm1, should be in $COMIN"
 else
  echo "can not find fire emission $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc"
  echo "can not find fire emission $COMINm1/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc"
  exit
 fi 
elif [ -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDY.nc ] && [ "${FLAG_TODAY_FIRE}" == "YES" ]; then
 COMIN9=$COMIN
 emisfile=GBBEPx_all01GRID.emissions_v003_$PDY.nc
 FIREDATE=$PDY
elif [ -s $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
 COMIN9=$COMIN
 emisfile=GBBEPx_all01GRID.emissions_v003_$PDYm1.nc
 FIREDATE=$PDYm1
elif [ -s $COMINm1/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc ]; then
  FIREDATE=$PDYm1
  emisfile=GBBEPx_all01GRID.emissions_v003_$PDYm1.nc
  COMIN9=$COMINm1
  echo "WARNING GBBEPx_all01GRID.emissions_v003_$PDYm1.nc found in $COMINm1, should be in $COMIN"
else
 echo "can not find fire emission $COMIN/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc"
 echo "can not find fire emission $COMINm1/GBBEPx_all01GRID.emissions_v003_$PDYm1.nc"
 exit
fi


FRPRATIO=${FRPRATIO:-1.0}
cat>gbbepx2pts.ini<<!
&control
efilein='$COMIN9/$emisfile'
markutc=18
burnarea_ratio=0.1
frpfactor=$FRPRATIO
startdate=${FIREDATE}06
nduration=127
tdiurnal=0.03033772, 0.03033772, 0.03033772, 0.03033772, 0.03033772,
       0.03033772, 0.03033772, 0.03434459, 0.03720664, 0.04006869,
       0.05724098, 0.07441328, 0.09158558, 0.09730967, 0.06868918,
       0.04006869, 0.03434459, 0.03033772, 0.03033772, 0.03033772,
       0.03033772, 0.03033772, 0.03033772, 0.03033772
dfrac=1.0,0.25,0.25
emname='CO','NO','NO2','SO2','NH3','PEC','POC','PMOTHR','PNO3','PSO4',
'PAL','PCA','PCL','PFE','PK','PMG','PMN','PNA','PNCOM','PNH4','PSI','PTI'
/

Species Converting Factor
'CO'      1   # kg ->mole
'CO'   35.7
'NOx'    2   # 90% to NO (mw 30), 10% to NO2 (mw 46), mw 31.6 in average, kg->mole
'NO'   28.481   'NO2'  3.164557
'SO2'    1    # kg -> mole
'SO2'  15.625
'NH3'    1
'NH3'  58.82
'BC'     1    # kg -> g  
'PEC'   0.  # 1000. 
'OC'     1
'POC'   0.  # 1000. 
'PM2.5' 16    # pm2.5 splitt factor kg -> g
'PEC' 94.9   'POC' 461.8  'PMOTHR'  13.7 'PNO3' 1.323 'PSO4' 12.6 
'PAL' 0.6075 'PCA' 3.858 'PCL' 41.5 'PFE' 0.434 'PK' 29.4
'PMG' 0.314  'PNA' 5.7335 'PNCOM' 323.2 'PNH4' 8.7915 'PSI' 1.8185  'PTI' 0.0515
!

export IOAPI_ISPH=20 # make consistent with met-preprocessor R_earth=6370000m

if [ $RUN = 'HI' ]; then
 export GRIDDESC=$PARMaqm/aqm_griddescHI
 export GRID_NAME=AQF_HI
 export TOPO=$FIXaqm/aqm_gridcro2d.landfac.HI.ncf
 DD=$RUN
elif [ $RUN = 'AK' ]; then
 export GRIDDESC=$PARMaqm/aqm_griddescAK
 export GRID_NAME=AQF_AK
 export TOPO=$FIXaqm/aqm_gridcro2d.landfac.AK.ncf
 DD=$RUN
else
#echo " unknown domain $RUN "
 export GRIDDESC=$PARMaqm/aqm_griddesc05
 export GRID_NAME=AQF_CONUS_5x
 export TOPO=$FIXaqm/aqm_gridcro2d.landfac.5x.ncf
 DD='cs'
fi

# output
export STACK_GROUP=aqm.$cycle.fire_location_$DD.ncf
export PTFIRE=aqm.$cycle.fire_emi_$DD.ncf

startmsg
$EXECaqm/aqm_gbbepx2pts.x
export err=$?;err_chk

if [ "$FCST" = "YES" ]; then
 CHK_DIR=$COMIN
else
 CHK_DIR=$COMINm1
fi

if [ -s $PTFIRE -a -s $STACK_GROUP ]; then

 if [ "$FCST" = "YES" ]; then
  cp -rp $DATA/aqm*fire*ncf $CHK_DIR
 else
  mv $DATA/aqm.$cycle.fire_location_${DD}.ncf $CHK_DIR/aqm.$cycle.fire_location_${DD}_r.ncf
  mv $DATA/aqm.$cycle.fire_emi_${DD}.ncf $CHK_DIR/aqm.$cycle.fire_emi_${DD}_r.ncf
 fi

else
 echo "gbbepx2emis run failed"
 exit 1
fi
