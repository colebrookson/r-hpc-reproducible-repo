IMAGE = colebrookson/r-hpc-reproducible-repo
TAG   = latest
SIF   = r-hpc-reproducible-repo.sif
AUTHOR = colebrookson

# build image
build:
	docker build -t $(IMAGE):$(TAG) .

# explicit AMD64 build-and-push
build-amd:
	DOCKER_BUILDKIT=1 docker build \
	  --platform linux/amd64 \
	  -t $(IMAGE):$(TAG) \
	  --push \
	  .
# for local testing only (loads into your local daemon)
build-amd-load:
	DOCKER_BUILDKIT=1 docker build \
	  --platform linux/amd64 \
	  -t $(IMAGE):$(TAG) \
	  --load \
	  .

# test locally (pipeline runs in container) 
run:
	docker run --rm -v $(PWD):/home/rproject -w /home/rproject $(IMAGE):$(TAG)

# drop into shell inside image 
shell:
	docker run --rm -it -v $(PWD):/home/rproject -w /home/rproject $(IMAGE):$(TAG) /bin/bash

# build Apptainer image from local Docker daemon 
sif: build
	singularity build $(SIF) docker-daemon://$(IMAGE):$(TAG)
