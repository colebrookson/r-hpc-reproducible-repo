IMAGE = colebrookson/r-hpc-reproducible-repo
TAG   = latest
SIF   = r-hpc-reproducible-repo.sif
AUTHOR = colebrookson

# any change to these files forces a local rebuild instead of a pull
BUILD_DEPS = Dockerfile DESCRIPTION sys_deps/sys_deps.sh

# hash of the build‑defining files
DEPS_HASH := $(shell sha256sum $(BUILD_DEPS) | sha256sum | cut -d' ' -f1)
LOCAL_IMG  = $(IMAGE):$(TAG)-$(DEPS_HASH)

# ensure‑image: (i) pull pre‑built image if present on Docker Hub
#                (ii) else build it locally with the hash‑tag
.PHONY: ensure-image
ensure-image:
	@if docker manifest inspect $(LOCAL_IMG) >/dev/null 2>&1; then \
	  echo "→ pulling pre‑built image $(LOCAL_IMG)"; \
	  docker pull $(LOCAL_IMG); \
	else \
	  echo "→ no pre‑built image for current spec; building…"; \
	  docker build -t $(LOCAL_IMG) .; \
	fi

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
