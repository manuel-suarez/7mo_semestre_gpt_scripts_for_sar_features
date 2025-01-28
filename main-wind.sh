#!/bin/bash
#
# We are looping over the image files and call the polarimetric decompositions SLURM scripts
# In this script we are waiting to last file generated to copy on siimon5 external disk drive

# First we are doing this in a sequentially manner

# Variable configurations
gpt=~/tools/esa-snap10.0/bin/gpt
dataset=cimat
base_path=~/data/cimat/dataset-$dataset
source=products
tiff=tiff
dest=wind
temp=temp4
num=$1
set -x
set -e
mkdir -p $base_path/$source
mkdir -p $base_path/$temp
mkdir -p $base_path/$dest
# Download list of files to process
scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/${source}_list${num}.txt $base_path/${source}_list${num}.txt
for fname in $(cat $base_path/${source}_list${num}.txt); do
  name=${fname%%.*}
  ext=${fname##*.}
  echo "Processing $name in bash script"
  echo "Extension $ext"
  # Transfer product from siimon5 GRD product directory
  scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/$source/$fname $base_path/$source/$fname
  # Unzip product and make temp directory
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
  # Due the windfield estimation step internet requirement we need to do that step in this script
  # and after that run the remaining steps of the second script

  # Run slurm preprocessing steps (step 1-5) script (on C0 cpu nodes)
  sbatch run-wind.slurm $base_path $source $dest $temp $fname 01
  # Wait until step 5 is finished
  while [ ! -f $base_path/$temp/$name/wind_05.dim ]; do
    # Sleep
    echo "$base_path/$temp/$name/wind_05 result has not been created, waiting 2m..."
    sleep 2m
  done
  echo "$base_path/$temp/$name/wind_05 result has been created, wait 5m and continue processing..."
  # We wait for if the GPT pipeline has not been finished
  sleep 5m
  # Run windfield estimation (step 6)
  if ! test -f $base_path/$temp/$name/wind_06.dim; then
    $gpt scripts/wind_06.xml -SsourceProduct=$base_path/$temp/$name/wind_05.dim -t $base_path/$temp/$name/wind_06.dim
  fi
  #
  # Run slurm postprocessing steps (step 7) script (on C0 cpu nodes)
  sbatch run-wind.slurm $base_path $source $dest $temp $fname 02
  # Wait until step 7 is finished
  while [ ! -f $base_path/$temp/$name/wind_07.dim ]; do
    # Sleep
    echo "$base_path/$temp/$name/wind_07 result has not been created, waiting 2m..."
    sleep 2m
  done
  echo "$base_path/$temp/$name/wind_07 result has been created, wait 5m and continue processing..."
  # We wait for if the GPT pipeline has not been finished
  sleep 5m
  # There is no extract vector data (SHP) on GPT pipeline so we need to read the CSV directly on the BEAM
  # data and processing with Geopandas and Rasterio to interpolate to Wind Field Image
  #
  # Transfer original TIFF image to get dimensions for interpolation
  scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/$tiff/$name.tif $base_path/$temp/$name.tif
  srun 
  # Move result to siimon5 (we are implementing an active waiting using sleep)
  # Once that result is created we move it to siimon5
  scp -P 2235 $base_path/$dest/${name}.tif manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-${dataset}/$dest/${name}.tif
  #scp -r -P 2235 $base_path/$dest/$name/${name}_VH.tif manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-noaa/sentinel1/wind/${name}_VH.tif
  # Remove temporary files 01-05
  #
  for step in 01 02 03 04 05 06 07
  do
    if test -d $base_path/$temp/$name/wind_${step}.data; then
      rm -rf $base_path/$temp/$name/wind_${step}.data
    fi
    if test -f $base_path/$temp/$name/wind_${step}.dim; then
      rm $base_path/$temp/$name/wind_${step}.dim
    fi
  done
  # Remove temp files
  if test -d $base_path/$temp/$name; then
    rm -rf $base_path/$temp/$name;
  fi
  if test -f $base_path/$temp/$name.tif; then
    rm $base_path/$temp/$name.tif
  fi
  # Remove tiff files
  if test -f $base_path/$dest/$name.tif; then
    rm $base_path/$dest/$name.tif
  fi
  # Remove unziped product
  if test -d $base_path/$source/$name.SAFE; then
    rm -rf $base_path/$source/$name.SAFE
  fi
  # Remove product file
  if test -f $base_path/$source/$fname; then
    rm $base_path/$source/$fname
  fi
  # Proceed with next file
done
