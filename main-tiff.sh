#!/bin/bash
#
# We are looping over the image files and call the polarimetric decompositions SLURM scripts
# In this script we are waiting to last file generated to copy on siimon5 external disk drive

# First we are doing this in a sequentially manner

# Variable configurations
gpt=~/tools/esa-snap10.0/bin/gpt
base_path=~/data/cimat/dataset-sentinel
source=GRD
dest=TIFF
temp=temp3
set -x
set -e
num=$1
# Download list of files to process
scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-noaa/sentinel1/${source}_list${num}.txt $base_path/${source}_list${num}.txt
for fname in $(cat $base_path/${source}_list${num}.txt); do
  name=${fname%%.*}
  echo "Processing $name in bash script"
  # Transfer product from siimon5 GRD product directory
  scp -P 2235 manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-noaa/sentinel1/$source/$fname $base_path/$source/$fname
  # Unzip product and make temp directory
  if [ ! -d $base_path/$source/$name.SAFE ]; then
    unzip -qo $base_path/$source/$fname -d $base_path/$source/
  fi
  mkdir -p $base_path/$temp/$name
  # Apply orbit file (we need internet access)
  if [ ! -f $base_path/$temp/$name/tiff_01.dim ]; then
    $gpt scripts/tiff_01.xml -SsourceProduct=$base_path/$source/$name.SAFE -t $base_path/$temp/$name/tiff_01.dim
  fi
  # Run slurm polarimetric decompositions script (on C0 cpu nodes)
  sbatch run-tiff.slurm $fname
  # Move result to siimon5 (we are implementing an active waiting using sleep)
  while [ ! -f $base_path/$dest/$name/${name}_VV.tif ]; do
    # Sleep
    echo "$base_path/$dest/$name result not created, waiting 30m..."
    sleep 30m
  done
  echo "$base_path/$dest/$name created, proceeding to move to siimon5"
  sleep 5m
  # Once that result is created we move it to siimon5
  scp -P 2235 $base_path/$dest/$name/${name}_VV.tif manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-noaa/sentinel1/TIFF/${name}_VV.tif
  #scp -r -P 2235 $base_path/$dest/$name/${name}_VH.tif manuelsuarez@siimon5.cimat.mx:~/data/cimat/dataset-noaa/sentinel1/TIFF/${name}_VH.tif
  # Remove temporary files 01-05
  #
  for step in 01 02 03 04 05
  do
    if test -d $base_path/$temp/$name/tiff_${step}.data; then
      rm -rf $base_path/$temp/$name/tiff_${step}.data
    fi
    if test -f $base_path/$temp/$name/tiff_${step}.dim; then
      rm $base_path/$temp/$name/tiff_${step}.dim
    fi
  done
  # Remove temp files
  if test -d $base_path/$temp/$name; then
    rm -rf $base_path/$temp/$name;
  fi
  # Remove tiff files
  if test -d $base_path/$dest/$name; then
    rm -rf $base_path/$dest/$name
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
