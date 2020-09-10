#!/bin/sh
# set -x
module load prod_util
module load prod_envir
NOW=$1
envir=prod
cyc=06
idir=${DCOMROOT}/${envir}/viirs
## export GVN_FHR=${GVN_FHR:-GVF-WKL-GLB_v2r3_j01} ## add this as default in ~/jobs/JAQM_PREP_CS
export GVN_FHR=${GVN_FHR:-GVF-WKL-GLB_v2r3_npp} ## add this as default in ~/jobs/JAQM_PREP_CS
SFHR=`echo ${GVN_FHR} | cut -c1-3`
#
# Searching for latest GVN file with 2 days back time latency on NCO $DCOMROOT
#
cdate=${NOW}${cyc}
PDYm2=$(${NDATE} -48 ${cdate} | cut -c1-8)
PDYm10=$(${NDATE} -240 ${cdate} | cut -c1-8)
FIRSTDAY=${PDYm2}
LASTDAY=${PDYm10}
NOW=${FIRSTDAY}
if [ -s tlist ]; then /bin/rm -f tlist; fi
while [ ${NOW} -ge ${LASTDAY} ]; do
   YM=`echo ${NOW} | cut -c1-6`
   ls ${idir}/${GVN_FHR}*_e${NOW}* > tlist
   if [ -s tlist ]; then break; fi
   cdate=${NOW}${cyc}
   NOW=$(${NDATE} -24 ${cdate} | cut -c1-8 )
done
end_day=$(tail tlist | awk -F"_e" '{print $2}' | cut -c1-8 )
filein_gvn=`tail tlist`
echo "Found GVN input file - ${filein_gvn}"
# ln -s ${filein_gvn} GVNIN
##
## Either redefine GVN for CMAQ runtime output or follow NESDIS naming
##
# export GVNOUT=CMAQ_GVN_${PDY}_nc
## OR
tmp1=$(echo ${filein_gvn} | awk -F${SFHR} '{print $2}' )
tmp2=$(echo ${tmp1} | awk -F'.' '{print $1}' )
fileout_gvn=${SFHR}${tmp2}.nc
echo "GVN input in  netcdf is ${fileout_gvn}"
#
# 
# exprot GVNOUT=${fileout_gvn}
# python ${USHAQM}/viirsgrib2nc4.py -vf ${GVNIN}
# if [ ! -s ${GVNOUT} ]; then echo "WARNING *** Can not find ${GVNOUT}"; fi
