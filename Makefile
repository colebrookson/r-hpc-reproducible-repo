IMAGE = r-hpc-reproducible-repo
TAG   = latest
SIF   = r-hpc-reproducible-repo.sif
AUTHOR = colebrookson

# build image
build:
	docker build -t $(IMAGE):$(TAG) .

# test locally (pipeline runs in container) 
run:
	docker run --rm -v $(PWD):/home/rproject -w /home/rproject $(IMAGE):$(TAG)

# drop into shell inside image 
shell:
	docker run --rm -it -v $(PWD):/home/rproject -w /home/rproject $(IMAGE):$(TAG) /bin/bash

# build Apptainer image from local Docker daemon 
sif: build
	singularity build $(SIF) docker-daemon://$(IMAGE):$(TAG)
