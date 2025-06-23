#!/bin/bash
#SBATCH --job-name=targets-demo
#SBATCH --output=slurm/logs/%x-%j.out
#SBATCH --error=slurm/logs/%x-%j.err
#SBATCH --time=12:00:00 # max on GRACE cluster is 1‑00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=general
#SBATCH --mail-type=END,FAIL

# load Apptainer and R module for non-container exec
module purge
module load Apptainer/1.2.2
module load R/4.4.1-foss-2022b  # <‑‑ “host‑side” R

# build the image once (NOTE you can also store a pre-built .sif)
IMG="$HOME/containers/rproj.sif"
if [ ! -f "$IMG" ]; then
    # echo "Building Apptainer image at $IMG"
    singularity build "$IMG" docker-daemon://rproj:latest
fi

# run the pipeline 
export TAR_RUN_ENV=hpc  
apptainer exec \
    # mounts  current dir on the host ($PWD) into  same path inside  container
    --bind "$PWD":"$PWD" \ 
    --pwd  "$PWD" \
    "$IMG" \
    Rscript -e "targets::tar_make()"
