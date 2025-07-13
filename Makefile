# let callers override on the command line or via .env
IMAGE ?= $(USER)/r-hpc-reproducible-repo
TAG   ?= latest          # e.g. make TAG=v0.2.1 push
SIF   = r-hpc-reproducible-repo.sif
AUTHOR ?= $(USER)

# any change to these files forces a local rebuild instead of a pull
BUILD_DEPS = Dockerfile DESCRIPTION sys_deps/sys_deps.sh

# ─── cross‑platform SHA helper ──────────────────────────────────────────────
# sha256sum exists on Linux; macOS has shasum -a 256
SHA ?= $(shell command -v sha256sum >/dev/null 2>&1 && echo sha256sum || echo "shasum -a 256")

# any change to these files forces a local rebuild instead of a pull
DEPS_HASH := $(shell cat $(BUILD_DEPS) | $(SHA) | $(SHA) | cut -d' ' -f1)
LOCAL_IMG  = $(IMAGE):$(TAG)-$(DEPS_HASH)
# does this docker client support `manifest inspect`?
HAVE_MANIFEST := $(shell docker manifest inspect hello-world >/dev/null 2>&1 && echo yes || echo no)

# ensure‑image: (i) pull pre‑built image if present on Docker Hub
#                (ii) else build it locally with the hash‑tag
.PHONY: ensure-image
ensure-image:
ifeq ($(HAVE_MANIFEST),yes)
	@if docker manifest inspect $(LOCAL_IMG) >/dev/null 2>&1; then \
	  echo "→ pulling pre‑built image $(LOCAL_IMG)"; \
	  docker pull $(LOCAL_IMG); \
	else \
	  echo "→ no pre‑built image for current spec; building…"; \
	  docker build -t $(LOCAL_IMG) .; \
	fi
else
	@echo "→ docker manifest not available; always building locally"; \
	docker build -t $(LOCAL_IMG) .
endif

# build image
build:
	docker build -t $(IMAGE):$(TAG) .

# explicit AMD64 build-and-push
build-amd:
	@command -v docker-buildx >/dev/null || { \
	    echo "Buildx not found  please update Docker Desktop ≥ 20.10"; exit 1; }
	DOCKER_BUILDKIT=1 docker buildx build \
	    --platform linux/amd64 \
	    -t $(IMAGE):$(TAG) --push .
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
SING2 ?= $(shell command -v singularity 2>/dev/null || command -v apptainer)
sif: build
	$(SING2) build $(SIF) docker-daemon://$(IMAGE):$(TAG)


# ADD SOME PUSH VERSIONS HERE FOR EASE
.PHONY: push push-amd

## push: build the default image (if needed) and upload it
push: build                 ## ⇒ docker push $(IMAGE):$(TAG)
	docker push $(IMAGE):$(TAG)

## push-amd: build linux/amd64 only and upload it
## keeps build‑and‑push separate so you can also call `make build-amd-load`
push-amd:
	@echo "→ building amd64 image and pushing to Docker Hub…"
	DOCKER_BUILDKIT=1 docker buildx build \
	  --platform linux/amd64 \
	  -t $(IMAGE):$(TAG) \
	  --push \
	  .