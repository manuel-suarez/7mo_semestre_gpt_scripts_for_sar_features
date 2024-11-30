#!/bin/bash

#SBATCH --partition=C0
#SBATCH --job-name=TiffExport
#SBATCH --time=0
#SBATCH --mem=0

srun bash make_tiff.sh ~/data/cimat/dataset-sentinel GRD TIFF temp3 $1
