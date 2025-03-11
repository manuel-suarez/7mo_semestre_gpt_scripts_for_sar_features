#!/bin/bash
#
# We are looping over the image files and call the polarimetric decompositions SLURM scripts
# In this script we are waiting to last file generated to copy on siimon5 external disk drive

# First we are doing this in a sequentially manner

# Variable configurations
gpt=~/tools/esa-snap10.0/bin/gpt
dataset=noaa
datadir=sentinel2
base_path=~/data/cimat/dataset-$dataset/$datadir
source=L2A
dest=tiff
temp=temp1
set -x
set -e
mkdir -p $base_path/$source
mkdir -p $base_path/$temp
mkdir -p $base_path/$dest
# Download list of files to process
#scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/${source}_list${num}.txt $base_path/${source}_list${num}.txt
for fname in $(cat $base_path/${source}_list.txt); do
  name=${fname%%.*}
  ext=${fname##*.}
  echo "Processing $name in bash script"
  echo "Extension $ext"
  # If final windfield zip file exists, continue
  if [ -f $base_path/$dest/${name}/B1.tif ]; then
    echo "$base_path/$dest/${name}/B1 band tiff file exists...., continue next"
    continue
  fi
  echo "Processing sentinel-2 bands extraction script"
  # Transfer product from siimon5 GRD product directory
  #if [ ! -f $base_path/$source/$fname ]; then
  #  scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/$source/$fname $base_path/$source/$fname
  #fi
  # Unzip product and make temp directory
  if [ $ext == "zip" ]; then
    if [ ! -d $base_path/$source/$name.SAFE ]; then
      unzip -qo $base_path/$source/$fname -d $base_path/$source/
    fi
  fi
  mkdir -p $base_path/$temp/$name
  # Resampling
  if ! test -f $base_path/$temp/$name/sen2_01.dim; then
    $gpt scripts/sen2_01.xml -SsourceProduct=$base_path/$source/$fname -t $base_path/$temp/$name/sen2_01.dim
  fi
  # Band subset
  for band in B1 B2 B3 B4 B5 B6 B6 B8 B8A B9 B11 B12; do
    if [ ! -f $base_path/$temp/$name/sen2_02_${band}.dim]; then
      $gpt scripts/sen02_02.xml -SsourceProduct=$base_path/$temp/$name/sen2_01.dim -Pband=${band} -t $base_path/$temp/$name/sen2_02_${band}.dim
    fi
    # Write
    if [ ! -f $base_path/$temp/$name/sen2_03_${band}.dim]; then
      $gpt scripts/sen2_03.xml -SsourceProduct=$base_path/$temp/$name/sen2_02_${band}.dim -PoutputFile=$base_path/$temp/$name_${band}.tif
    fi
    # Move to destination
    mv $base_path/$temp/$name_${band}.tif $base_path/$dest/$name_${band}.tif
  done
  # Delete temp files and directories
  for band in B1 B2 B3 B4 B5 B6 B6 B8 B8A B9 B11 B12; do
    if test -d $base_path/$temp/$name/sen2_02_${band}.data; then
      rm -rf $base_path/$temp/$name/sen2_02_${band}.data
    fi
    if test -f $base_path/$temp/$name/sen2_02_${band}.dim; then
      rm $base_path/$temp/$name/sen2_02_${band}.dim
    fi
  done
  if [ -f $base_path/$temp/$name/sen2_01.dim]; then
    rm -rf $base_path/$temp/$name/sen2_01.data;
    rm $base_path/$temp/$name/sen2_01.dim;
  fi
  # Remove temp files
  if test -d $base_path/$temp/$name; then
    rm -rf $base_path/$temp/$name;
  fi
  # Remove unziped product
  if test -d $base_path/$source/$name.SAFE; then
    rm -rf $base_path/$source/$name.SAFE
  fi
  # Remove product file (on SIIMON5 not remove)
  #if test -f $base_path/$source/$fname; then
  #  rm $base_path/$source/$fname
  #fi
  # Proceed with next file
done
