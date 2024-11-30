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
if ! test -f $base_path/$temp/$name/glm_01.dim; then
  $gpt scripts/glm-gen_01.xml -SsourceProduct=$base_path/$source/$name.SAFE -t $base_path/$temp/$name/glm_01.dim
fi
# Calibration
if ! test -f $base_path/$temp/$name/glm_02.dim; then
  $gpt scripts/glm-gen_02.xml -SsourceProduct=$base_path/$temp/$name/glm_01.dim -t $base_path/$temp/$name/glm_02.dim
fi
# Speckle filter (Lee)
if ! test -f $base_path/$temp/$name/glm_03.dim; then
  $gpt scripts/glm-gen_03.xml -SsourceProduct=$base_path/$temp/$name/glm_02.dim -t $base_path/$temp/$name/glm_03.dim
fi
# Ellipsoid correction
if ! test -f $base_path/$temp/$name/glm_04.dim; then
  $gpt scripts/glm-gen_04.xml -SsourceProduct=$base_path/$temp/$name/glm_03.dim -t $base_path/$temp/$name/glm_04.dim
fi
# Linear conversion
if ! test -f $base_path/$temp/$name/glm_05.dim; then
  $gpt scripts/glm-gen_05.xml -SsourceProduct=$base_path/$temp/$name/glm_04.dim -t $base_path/$temp/$name/glm_05.dim
fi
# GLCM matrix generation
if ! test -f $base_path/$temp/$name/glm_06.dim; then
  $gpt scripts/glm-gen_06.xml -SsourceProduct=$base_path/$temp/$name/glm_05.dim -t $base_path/$temp/$name/glm_06.dim
fi
# $gpt scripts/sar_export_to_tif.xml -SsourceProduct=dataset-sentinel/temp/$NAME.dim -t dataset-sentinel/GRD_tif/$NAME.tif
mv $base_path/$temp/$name/glm_06.data $base_path/$dest/$name/glm_06.data
mv $base_path/$temp/$name/glm_06.dim $base_path/$dest/$name/glm_06.dim
