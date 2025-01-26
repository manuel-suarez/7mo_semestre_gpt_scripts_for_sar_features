#!/bin/bash
gpt=~/tools/esa-snap10.0/bin/gpt
base_path=$1
source=$2
dest=$3
temp=$4
fname=$5

name=${fname%%.*}
echo $name
ext=${fname##*.}
echo $ext

set -x
set -e

# Unzip if is a sentinel product (zip extension)
if [ $ext == "zip" ]; then
  if [ ! -d $base_path/$source/$name.SAFE ]; then
    unzip -qo $base_path/$source/$fname -d $base_path/$source/
  fi
fi
mkdir -p $base_path/$temp/$name
# Apply thermal noise removal (only if Sentinel)
if ! test -f $base_path/$temp/$name/wind_01.dim; then
  # Only for Sentinel-1 products
  if [ $ext == "zip" ]; then
    $gpt scripts/wind_01.xml -SsourceProduct=$base_path/$source/$fname -t $base_path/$temp/$name/wind_01.dim
  fi
fi
# Apply orbit file
if ! test -f $base_path/$temp/$name/wind_02.dim; then
  # If product is ENVISAT ASAR (N1 extension) apply operator on product
  if [ $ext == "N1" ]; then
    $gpt scripts/wind_02.xml -SsourceProduct=$base_path/$source/$fname -t $base_path/$temp/$name/wind_02.dim
  else
    $gpt scripts/wind_02.xml -SsourceProduct=$base_path/$temp/$name/wind_01.dim -t $base_path/$temp/$name/wind_02.dim
  fi
fi
# Remove GRD Border Noise
if ! test -f $base_path/$temp/$name/wind_03.dim; then
  $gpt scripts/wind_03.xml -SsourceProduct=$base_path/$temp/$name/wind_02.dim -t $base_path/$temp/$name/wind_03.dim
fi
# Land-Sea mask
if ! test -f $base_path/$temp/$name/wind_04.dim; then
  $gpt scripts/wind_04.xml -SsourceProduct=$base_path/$temp/$name/wind_03.dim -t $base_path/$temp/$name/wind_04.dim
fi
# Calibration
if ! test -f $base_path/$temp/$name/wind_05.dim; then
  $gpt scripts/wind_05.xml -SsourceProduct=$base_path/$temp/$name/wind_04.dim -t $base_path/$temp/$name/wind_05.dim
fi
# Wind-field estimation
if ! test -f $base_path/$temp/$name/wind_06.dim; then
  $gpt scripts/wind_06.xml -SsourceProduct=$base_path/$temp/$name/wind_05.dim -t $base_path/$temp/$name/wind_06.dim
fi
# Terrain correction
if ! test -f $base_path/$temp/$name/wind_07.dim; then
  $gpt scripts/wind_07.xml -SsourceProduct=$base_path/$temp/$name/wind_06.dim -t $base_path/$temp/$name/wind_07.dim
fi
# Write to output file
if ! test -f $base_path/$temp/$name.tif; then
  $gpt scripts/wind_08.xml -SsourceProduct=$base_path/$temp/$name/wind_07.dim -PoutputFile=$base_path/$temp/$name.tif
fi
# Copy wind tiff result to destionation directory
mv $base_path/$temp/$name.tif $base_path/$dest/$name.tif
