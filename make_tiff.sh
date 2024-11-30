#!/bin/bash
gpt=~/tools/esa-snap10.0/bin/gpt
base_path=$1
source=$2
dest=$3
temp=$4
fname=$5

name=${fname%%.*}
echo $name

set -x
set -e
if [ ! -d $base_path/$source/$name.SAFE ]; then
  unzip -qo $base_path/$source/$fname -d $base_path/$source/
fi
mkdir -p $base_path/$temp/$name
mkdir -p $base_path/$dest/$name
# Apply orbit file
if ! test -f $base_path/$temp/$name/tiff_01.dim; then
  $gpt scripts/tiff_01.xml -SsourceProduct=$base_path/$source/$name.SAFE -t $base_path/$temp/$name/tiff_01.dim
fi
# Calibration
if ! test -f $base_path/$temp/$name/tiff_02.dim; then
  $gpt scripts/tiff_02.xml -SsourceProduct=$base_path/$temp/$name/tiff_01.dim -t $base_path/$temp/$name/tiff_02.dim
fi
# Multilook
if ! test -f $base_path/$temp/$name/tiff_03.dim; then
  $gpt scripts/tiff_03.xml -SsourceProduct=$base_path/$temp/$name/tiff_02.dim -t $base_path/$temp/$name/tiff_03.dim
fi
# Ellipsoid correction
if ! test -f $base_path/$temp/$name/tiff_04.dim; then
  $gpt scripts/tiff_04.xml -SsourceProduct=$base_path/$temp/$name/tiff_03.dim -t $base_path/$temp/$name/tiff_04.dim
fi
# Linear conversion of VV band
if ! test -f $base_path/$temp/$name/${name}_VV.tif; then
  $gpt scripts/tiff_05.xml -SsourceProduct=$base_path/$temp/$name/tiff_04.dim -SsourceBand=Sigma0_VV -t $base_path/$temp/$name/${name}_VV.tif
fi
# Linear conversion of VH band
if ! test -f $base_path/$temp/$name/${name}_VH.tif; then
  $gpt scripts/tiff_05.xml -SsourceProduct=$base_path/$temp/$name/tiff_04.dim -SsourceBand=Sigma0_VH -t $base_path/$temp/$name/${name}_VH.tif
fi
# $gpt scripts/sar_export_to_tif.xml -SsourceProduct=dataset-sentinel/temp/$NAME.dim -t dataset-sentinel/GRD_tif/$NAME.tif
mv $base_path/$temp/$name/${name}_VV.tif $base_path/$dest/$name/${name}_VV.tif
mv $base_path/$temp/$name/${name}_VH.tif $base_path/$dest/$name/${name}_VH.tif
