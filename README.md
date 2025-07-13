# Reproducible Targets Pipeline – Getting Started

The goal of this repository is to provide a **reproducible R modelling pipeline** that runs an analysis geared towards a Bayesian statistical modeling framework, using the `targets` package for reproducible workflows. The pipeline is designed to be run in a Docker container, which can be executed locally or on a high-performance computing (HPC) cluster. It is only Bayesian in the sense that it uses `rstanarm` for model fitting, but the pipeline can be adapted to other modelling frameworks like `NIMBLE` or `brms`. Rstan/rstanarm is used here as an example since it requires a C++ compiler and is a common choice for Bayesian modelling in R. More on that later. 

## What is this repository for (analysis-type wise)?
***A key note here** is that this pipeline is NOT optimized for speed or efficiency, but rather for **reproducibility** and ease of use. It is designed to be run with minimal setup, making it accessible for users who may not have extensive experience with R or Docker. The pipeline is structured to allow for easy modification and extension, so you can adapt it to your specific needs. Please note that this is a **demo pipeline** and not a production-ready solution. It is meant to serve as a starting point for your own reproducible modelling projects. **As an aside**, in general, some good advice I've gotten is that if you're interested in doing HPC work, you should probably stay as close to the machine as possible. That is, the use of tools and languages and packages and dependencies that take you further away from the physical machine you're on will likely a) slow you down significantly, and b) make it MUCH harder to debug issues. This is absolutely not a principle that is followed in this repository. This is because this is built for the use case of "most of my work can be done locally and I want all the modern reproducibility tools that work nice locally, but I will also need, at some point, to run a bunch of models on a cluster because it would just take too long locally". If you are running TRULY large models or simulations, you should a) probably ditch `targets`, and b) probably ditch Stan. Heck, you should ditch R altogether and use something else like Julia or C++. This is for the R-users who need an in-between solution and are NOT going to spend a lot of time speeding up their workflow.*

Key here is that you should be able to run this pipeline host-side or on an HPC cluster with minimal setup, and without needing to install R or any packages on the host system. This guide will walk you through the steps to get started. It assumes you're familiar with basic R (specifically the `targets` package) and Docker concepts, but it will guide you through the process of running the pipeline.

> Run the full **Bayesian modelling demo** locally or on an HPC in minutes,
> with no host–side R installation required.

---

## Some basics on the contents of this repository

The table below is an overhead view of the repository structure.  Read this first—it shows where each moving part lives and saves you from grepping the entire tree.

| Folder / file                   | Purpose                                                   |
|---------------------------------|-----------------------------------------------------------|
| `Dockerfile`, `sys_deps/`       | Builds the container image (or pull it ready‑made).       |
| `R/`                     | Data‑simulation script, helper functions, `_targets.R`.   |
| `slurm/`                        | Templates & launcher to run the same container on SLURM.  |
| `Makefile`                      | **One‑command** UX: `make build` · `make run` · `make push`. |
| `current_targets.png`           | Auto‑generated DAG of the pipeline (see §5).              |

---

## 1 · Prerequisites

| Tool             | Minimum Version | Quick check                             |
|------------------|-----------------|-----------------------------------------|
| **Docker**       | $\geq 24$            | `docker --version`                      |
| **GNU make**     | any             | `make --version`                        |
| **Git**          | $\geq 2.40$             | `git --version`                         |
| **(Optional) Apptainer/Singularity** | 1.2+ (HPC only) | `apptainer --version` |

---

## Fork & run under *your* Docker Hub namespace

Want to publish your *own* image (instead of pushing to
`colebrookson/r-hpc-reproducible-repo`)?  
Just override two variables when you call `make`.

```bash
# 1. Pick a namespace and tag
export IMAGE=myhubuser/r-demo          # or ghcr.io/<org>/r-demo
export TAG=v0.1.0                      # any label you like

# 2. Build the image locally
make build                              # uses ${IMAGE}:${TAG}

# 3. Push it to your registry (after `docker login`)
make push                               # pushes ${IMAGE}:${TAG}

# 4. Run the pipeline with that same tag
make run                                # mounts your repo, executes inside container
```

## Clone & run with the pre‑built image

If you have Docker installed, you can run the pipeline immediately
without building the image yourself. This is the recommended way to get started. Eventually you may want to build the image yourself with the dependencies you'll need, but for now, let's use the pre-built image.

```bash
git clone https://github.com/<YOUR-ORG>/r-hpc-reproducible-repo.git
cd r-hpc-reproducible-repo
make run            # pulls colebrookson/r-hpc-reproducible-repo:latest if missing
```

*First run downloads ≈ 2 GB; subsequent runs start instantly.*

Outputs appear in:

| Path                           | Contents                               |
|--------------------------------|----------------------------------------|
| `_targets/objects/`            | Fitted Stan models (`.qs`)             |
| `example/outputs/model_waic.tex` | LaTeX WAIC table                      |
| `example/figs/`                | Density / pairs / effect PNGs         |
| `current_targets.png`          | Visual DAG snapshot (see §5)           |

---

## 3 · Building the image yourself (optional)

```bash
make build        # fully reproducible local build
make push         # push to your Docker Hub repo (if you have one)
```

`make build` reuses cached layers; editing `DESCRIPTION` or `sys_deps.sh`
triggers only the minimal rebuild.

---

## 4 · Running on SLURM with Apptainer

```bash
make sif                          # converts Docker image → .sif
sbatch slurm/submit-targets.sh    # submits the orchestrator job
```

The orchestrator auto‑detects how many model specs exist and launches one
worker per spec (capped at 32) via **clustermq**; each worker re‑enters the
same `.sif`.

---

## 5 · Pipeline graph (auto‑generated)

Every time you run `make run` or the SLURM job, a fresh DAG is saved:

```r
# executed automatically inside the container
vis <- targets::tar_visnetwork(targets_only = TRUE, reporter = "silent")
visNetwork::visSave(vis, "current_targets.html")
if (requireNamespace("webshot2", quietly = TRUE)) {
  webshot2::webshot("current_targets.html", "current_targets.png",
                    vwidth = 1600, vheight = 900)
}
```

`current_targets.png` lives in the repo root; open it to understand the current
target topology.

*(Requires `visNetwork` and `webshot2`, already installed in the image.)*

---

## 6 · Troubleshooting ☂

| Symptom / log snippet                           | Likely cause                | Fix |
|-------------------------------------------------|-----------------------------|-----|
| `Cannot connect to the Docker daemon…`          | User not in `docker` group  | `sudo usermod -aG docker $USER && log out/in` |
| `package ‘xyz’ is not available` during build   | Missing system libraries    | Add `apt-get` line in `sys_deps/sys_deps.sh`, then `make build` |
| `Error: object of type 'closure' is not…` in targets | Mis‑shaped grid / split bug | Re‑run after editing `example/R/model_grid.R` (see code comments) |
| SLURM jobs pending forever                      | Partition limits            | Adjust `--partition` and `--mem` in `slurm/submit-targets.sh` |

---

## 7 · Advanced / Customising the stack

### 7.1 Add or switch modelling back‑ends (e.g. **NIMBLE**)

1. **R package**  
   *Add to* `DESCRIPTION → Imports:`  

   ```diff
   +    nimble,
   ```

2. **System libraries**  
   NIMBLE needs a Fortran compiler and OpenMP (already present).  
   If additional libs are required, append them to `sys_deps/sys_deps.sh`
   (`libopenblas-dev`, `gfortran`, etc. are already installed).

3. **Re‑build**  

   ```bash
   make build push      # local + Docker Hub
   # or just `make build` if working offline
   ```

4. **Use in targets**  
   Create new helpers in `example/R/` (e.g., `fit_nimble_models.R`) and add a
   new `tar_plan` to `_targets.R`.

### 7.2 When a package fails to compile

1. Read the last 40 lines of the build log (`make build |& tee build.log`).  
2. Identify missing *header* or *symbol* (e.g., `hdf5.h` → `libhdf5-dev`).  
3. Edit `sys_deps/sys_deps.sh`, add the `apt-get install` line.  
4. Re‑run `make build`.

### 7.3 Changing Stan resource use

*   **CPU / wall‑time per worker**: edit `slurm/clustermq.tmpl`
    (`n_cpus`, `walltime`).  
*   **Chains / iterations**: edit `fit_one_model()` in
    `example/R/fit_models.R`.

### 7.4 Running *without* Docker

```r
# install R 4.4, then
install.packages(c("targets", "tarchetypes", "rstanarm", "qs2", …))
source("packages.R"); targets::tar_make()
```

…but expect more friction (compiler toolchain, matching R versions).

---

## 8 · Where to ask questions

* **GitHub Issues** — bug reports & feature requests.  
* Package‑specific questions — their respective repos (rstanarm, targets, etc.).  
* HPC quirks — contact your cluster admins (e.g., check available R modules).

---

Happy reproducible modelling! 
