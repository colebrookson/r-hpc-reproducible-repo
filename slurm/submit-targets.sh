#!/bin/bash
#SBATCH --job-name=targets-demo
#SBATCH --output=slurm/logs/%x-%j.out
#SBATCH --error=slurm/logs/%x-%j.err
#SBATCH --time=12:00:00 # max on GRACE cluster is 1‑00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
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

# figure out how many models are defined in model_grid.R
N_MODELS=$(apptainer exec \
  --bind "$PWD":"$PWD" --pwd "$PWD" "$IMG" \
  Rscript --vanilla -e \
  'targets::tar_source("./example/R"); \
    cat(nrow(build_model_grid()))')

# each model uses 4 CPU cores
CORES_PER_MODEL=4

# hard upper‑limit so you don’t swamp the cluster
MAX_WORKERS=64
WORKERS=$(( N_MODELS < MAX_WORKERS ? N_MODELS : MAX_WORKERS ))

echo "Will run $WORKERS parallel models out of $N_MODELS total"

# launch the pipeline with that many workers
apptainer exec \
  --bind "$PWD":"$PWD" --pwd "$PWD" "$IMG" \
  Rscript --vanilla -e \
  "targets::tar_make_clustermq(workers = $WORKERS)"
