CRYSTAL=/usr/bin/crystal
CRYSTAL_FLAGS=--release

VERSION := $(shell ./bin/git_version)

all: clean fmt test build docker_build ## clean and produce target binary and docker image

test: ## runs crystal tests
	$(CRYSTAL) spec spec/*.cr

fmt: ## format the crystal sources
	$(CRYSTAL) tool format

build: ## compiles from crystal sources
	mkdir -p bin
	$(CRYSTAL) build $(CRYSTAL_FLAGS) src/entrypoint/git_version.cr -o bin/git_version

.PHONY: docker
docker: build docker_build ## compiles from sources and produce the docker image

docker_build: ## build the docker image
	docker build -t codacy/git_version:${VERSION} .

clean: ## clean target directories
	rm -rf bin

.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push codacy/git_version:$(VERSION)

.PHONY: push-latest-docker-image
push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker tag codacy/git_version:$(VERSION) codacy/git_version:latest &&\
	docker push codacy/git_version:latest

.PHONY: help
help:
	@echo "make help"
	@echo "\n"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\n"
