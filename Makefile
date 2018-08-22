.DEFAULT-GOAL := help

# Variables
PROJECT_NAME?=$$(git remote -v | head -n1 | awk '{print $$2}' | sed 's/.*\///' | sed 's/\.git//')
CWD=$(shell pwd)
VERSION_NUMBER?=$$(docker run -v $(CWD):/repo codacy/ci-git-version:latest)## lazy. run with VERSION_NUMBER=x to prevent slow runs

.PHONY: help get-next-version-number build push-docker-image push-latest-docker-image
help:
	@echo "---------------------------------------------------------------------------------------------------------"
	@echo "build and deploy help"
	@echo "---------------------------------------------------------------------------------------------------------"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "---------------------------------------------------------------------------------------------------------"

get-next-version-number: ## get next version number
	@echo $(VERSION_NUMBER)

build: ## build docker image
	docker build -t codacy/$(PROJECT_NAME):$(VERSION_NUMBER) .

push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push codacy/$(PROJECT_NAME):$(VERSION_NUMBER)

push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker tag codacy/$(PROJECT_NAME):$(VERSION_NUMBER) codacy/$(PROJECT_NAME):latest &&\
	docker push codacy/$(PROJECT_NAME):latest

git-tag: ## tag the current commit with the next version and push
	git tag $(VERSION_NUMBER) &&\
	git push --tags
