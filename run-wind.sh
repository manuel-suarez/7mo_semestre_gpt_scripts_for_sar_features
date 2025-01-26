#!/bin/bash

#SBATCH --partition=C0
#SBATCH --job-name=WindGeneration
#SBATCH --time=0
#SBATCH --mem=0

base_path=$1
source=$2
dest=$3
temp=$4
fname=$5

srun bash make_wind.sh $base_path $source $dest $temp $fname
