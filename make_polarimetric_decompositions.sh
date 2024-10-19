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
$gpt scripts/polarimetric_01.xml -SsourceProduct=$base/$source/$name.SAFE -t $base/$temp/$name/pol_01.dim
# TOPSAR Split subswath
$gpt scripts/polarimetric_02.xml -SsourceProduct=$base/$temp/$name/pol_01.dim -Psubswath=IW1 -t $base/$temp/$name/pol_02_iw1.dim
$gpt scripts/polarimetric_02.xml -SsourceProduct=$base/$temp/$name/pol_01.dim -Psubswath=IW2 -t $base/$temp/$name/pol_02_iw2.dim
$gpt scripts/polarimetric_02.xml -SsourceProduct=$base/$temp/$name/pol_01.dim -Psubswath=IW3 -t $base/$temp/$name/pol_02_iw3.dim
# Calibrate splits
$gpt scripts/polarimetric_03.xml -SsourceProduct=$base/$temp/$name/pol_02_iw1.dim -t $base/$temp/$name/pol_03_iw1.dim
$gpt scripts/polarimetric_03.xml -SsourceProduct=$base/$temp/$name/pol_02_iw2.dim -t $base/$temp/$name/pol_03_iw2.dim
$gpt scripts/polarimetric_03.xml -SsourceProduct=$base/$temp/$name/pol_02_iw3.dim -t $base/$temp/$name/pol_03_iw3.dim
# TOPSAR Deburst splits
$gpt scripts/polarimetric_04.xml -SsourceProduct=$base/$temp/$name/pol_03_iw1.dim -t $base/$temp/$name/pol_04_iw1.dim
$gpt scripts/polarimetric_04.xml -SsourceProduct=$base/$temp/$name/pol_03_iw2.dim -t $base/$temp/$name/pol_04_iw2.dim
$gpt scripts/polarimetric_04.xml -SsourceProduct=$base/$temp/$name/pol_03_iw3.dim -t $base/$temp/$name/pol_04_iw3.dim
# TOPSAR Merge
$gpt scripts/polarimetric_05.xml -Ssource1=$base/$temp/$name/pol_04_iw1.dim -Ssource2=$base/$temp/$name/pol_04_iw2.dim -Ssource3=$base/$temp/$name/pol_04_iw3.dim -t $base/$temp/$name/pol_05.dim
# Polarimetric Matrix 
$gpt scripts/polarimetric_06.xml -SsourceProduct=$base/$temp/$name/pol_05.dim -t $base/$temp/$name/pol_06.dim
# Multilook
$gpt scripts/polarimetric_07.xml -ssourceproduct=$base/$temp/$name/pol_06.dim -t $base/$temp/$name/pol_07.dim
# Speckle filter (Lee)
$gpt scripts/polarimetric_08.xml -ssourceproduct=$base/$temp/$name/pol_07.dim -t $base/$temp/$name/pol_08.dim
# Polarimetric decomposition
$gpt scripts/polarimetric_09.xml -ssourceproduct=$base/$temp/$name/pol_08.dim -t $base/$temp/$name/pol_09.dim
# Ellipsoid correction
$gpt scripts/polarimetric_10.xml -ssourceproduct=$base/$temp/$name/pol_09.dim -t $base/$temp/$name/pol_10.dim
# Land mask
$gpt scripts/polarimetric_11.xml -ssourceproduct=$base/$temp/$name/pol_10.dim -t $base/$temp/$name/pol_11.dim
# $gpt scripts/sar_export_to_tif.xml -SsourceProduct=dataset-sentinel/temp/$NAME.dim -t dataset-sentinel/GRD_tif/$NAME.tif
