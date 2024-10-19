#!/bin/bash
gpt=~/tools/snap/bin/gpt
base=~/data/cimat/dataset-sentinel
source=SLC
dest=POL
temp=temp7
fname=$1

name=${fname%%.*}
echo $name

# Apply orbit file
set -x
set -e
mkdir -p $base/$temp/$name
if ! test -f $base/$temp/$name/pol_01.dim; then
  $gpt scripts/polarimetric_01.xml -SsourceProduct=$base/$source/$name.SAFE -t $base/$temp/$name/pol_01.dim
fi
# TOPSAR Split subswath
for n in 1 2 3
do
  if ! test -f $base/$temp/$name/pol_02_iw${n}.dim; then
    $gpt scripts/polarimetric_02.xml -SsourceProduct=$base/$temp/$name/pol_01.dim -Psubswath=IW${n} -t $base/$temp/$name/pol_02_iw${n}.dim
  fi
done
# Calibrate splits
for n in 1 2 3 
do
  if ! test -f $base/$temp/$name/pol_03_iw${n}.dim; then
    $gpt scripts/polarimetric_03.xml -SsourceProduct=$base/$temp/$name/pol_02_iw${n}.dim -t $base/$temp/$name/pol_03_iw${n}.dim
  fi
done
# TOPSAR Deburst splits
for n in 1 2 3 
do
  if ! test -f $base/$temp/$name/pol_04_iw${n}.dim; then
    $gpt scripts/polarimetric_04.xml -SsourceProduct=$base/$temp/$name/pol_03_iw${n}.dim -t $base/$temp/$name/pol_04_iw${n}.dim
  fi
done
# TOPSAR Merge
if ! test -f $base/$temp/$name/pol_05.dim; then
  $gpt scripts/polarimetric_05.xml -Ssource1=$base/$temp/$name/pol_04_iw1.dim -Ssource2=$base/$temp/$name/pol_04_iw2.dim -Ssource3=$base/$temp/$name/pol_04_iw3.dim -t $base/$temp/$name/pol_05.dim
fi
# Polarimetric Matrix 
if ! test -f $base/$temp/$name/pol_06.dim; then
  $gpt scripts/polarimetric_06.xml -SsourceProduct=$base/$temp/$name/pol_05.dim -t $base/$temp/$name/pol_06.dim
fi
# Multilook
if ! test -f $base/$temp/$name/pol_07.dim; then
  $gpt scripts/polarimetric_07.xml -SsourceProduct=$base/$temp/$name/pol_06.dim -t $base/$temp/$name/pol_07.dim
fi
# Speckle filter (Lee)
if ! test -f $base/$temp/$name/pol_08.dim; then
  $gpt scripts/polarimetric_08.xml -SsourceProduct=$base/$temp/$name/pol_07.dim -t $base/$temp/$name/pol_08.dim
fi
# Polarimetric decomposition
if ! test -f $base/$temp/$name/pol_09.dim; then
  $gpt scripts/polarimetric_09.xml -SsourceProduct=$base/$temp/$name/pol_08.dim -t $base/$temp/$name/pol_09.dim
fi
# Ellipsoid correction
if ! test -f $base/$temp/$name/pol_10.dim; then
  $gpt scripts/polarimetric_10.xml -SsourceProduct=$base/$temp/$name/pol_09.dim -t $base/$temp/$name/pol_10.dim
fi
# Land mask
if ! test -f $base/$temp/$name/pol_11.dim; then
  $gpt scripts/polarimetric_11.xml -SsourceProduct=$base/$temp/$name/pol_10.dim -t $base/$temp/$name/pol_11.dim
fi
# $gpt scripts/sar_export_to_tif.xml -SsourceProduct=dataset-sentinel/temp/$NAME.dim -t dataset-sentinel/GRD_tif/$NAME.tif
