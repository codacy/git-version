CRYSTAL?=$(shell which crystal)
CRYSTAL_FLAGS=--release
CRYSTAL_STATIC_FLAGS=--static
VERSION?=$(shell cat .version)

all: fmt test build docker_build ## clean and produce target binary and docker image

.PHONY: test
test: ## runs crystal tests
	$(CRYSTAL) spec spec/*.cr

.PHONY: fmt
fmt: ## format the crystal sources
	$(CRYSTAL) tool format

build: ## compiles from crystal sources
	mkdir -p bin
	$(CRYSTAL) build $(CRYSTAL_FLAGS) src/main.cr -o bin/git-version

.PHONY: buildStatic
buildStatic: ## compiles from crystal sources into static binary
	mkdir -p bin
	crystal build $(CRYSTAL_FLAGS) $(CRYSTAL_STATIC_FLAGS) src/main.cr -o bin/git-version

docker_build: ## build the docker image
	docker build -t codacy/git-version:$(VERSION) .

.PHONY: clean
clean: ## clean target directories
	rm -rf bin

.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker build -t codacy/git-version:$(VERSION) . &&\
	docker push codacy/git-version:$(VERSION)

.PHONY: push-latest-docker-image
push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker build -t codacy/git-version:latest . &&\
	docker push codacy/git-version:latest

.PHONY: help
help:
	@echo "make help"
	@echo "\n"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\n"
