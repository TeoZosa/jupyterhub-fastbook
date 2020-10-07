define DESCRIPTION
* Deploy $(PROJECT_NAME) to your Kubernetes cluster via the official Helm chart.
* Build and push your own $(PROJECT_NAME) images to your Docker registry.
Note:
* To override any environment variables, do so when specifying your desired goal.
  E.g., `make deploy TAG=latest`
* This makefile utilizes strong tagging for unambiguous container image provenance.
  Unless you are pushing and pulling to your own registry, you *MUST* override the
  the generated tag with your desired tag when deploying to your own cluster (see above).
endef

#################################################################################
# CONFIGURATIONS                                                                #
#################################################################################

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

#################################################################################
# GLOBALS                                                                       #
#################################################################################

REGISTRY_NAMESPACE = teozosa
PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME := $(shell basename $(PROJECT_DIR))
DOCKER_REPO = $(REGISTRY_NAMESPACE)/$(PROJECT_NAME)

# List any changed files (excluding submodules)
CHANGED_FILES := $(shell git diff --name-only)

ifeq ($(strip $(CHANGED_FILES)),)
GIT_VERSION := $(shell git describe --tags --long --always)
else
diff_checksum := $(shell git diff | shasum -a 256 | cut -c -6)
GIT_VERSION := $(shell git describe --tags --long --always --dirty)-$(diff_checksum)
endif
TAG := $(shell date +v%Y%m%d)-$(GIT_VERSION)
IMG = $(DOCKER_REPO):$(TAG)

CONFIG_FILE := config.yaml


#################################################################################
# HELPER TARGETS                                                                #
#################################################################################

.PHONY: all
all: build push $(CONFIG_FILE) deploy

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
	  $(error Undefined $1$(if $2, ($2))))

.PHONY: validate_req_env_vars
validate_req_env_vars: REQ_ENV_VARS = DOCKER_REPO IMG PROJECT_NAME REGISTRY_NAMESPACE TAG $(TARGET_SPECIFIC_REQ_ENV_VARS)
validate_req_env_vars:
	$(foreach REQ_ENV_VAR,$(REQ_ENV_VARS),$(call check_defined, $(REQ_ENV_VAR), Required!))


#################################################################################
# COMMANDS                                                                      #
#################################################################################

.PHONY: build
## Build docker container
build: export DOCKER_BUILDKIT=1# Dockerfile uses Docker BuildKit features for performance
build: LATEST_IMG = $(DOCKER_REPO):latest
build: TARGET_SPECIFIC_REQ_ENV_VARS := DOCKER_BUILDKIT LATEST_IMG # Fail if not defined
build: validate_req_env_vars
	docker build --tag $(IMG) .
	@echo Built $(IMG)
	@if ! [ "$(TAG)" = latest ]; then \
		docker tag $(IMG) $(LATEST_IMG) && \
		echo Built $(LATEST_IMG); \
	fi

.PHONY: push
## Push image to Docker Hub container registry
push: validate_req_env_vars
	docker push "$(IMG)"
	@echo Exported $(DOCKER_REPO) with  :$(TAG) tags \
		to Docker Hub image registry

.PHONY: deploy
## Deploy JupyterHub to your Kubernetes cluster
deploy: RELEASE := jhub
deploy: NAMESPACE := jhub
deploy: VER := 0.9.1
deploy: TARGET_SPECIFIC_REQ_ENV_VARS := RELEASE NAMESPACE VER # Fail if not defined
deploy: validate_req_env_vars $(CONFIG_FILE)
ifeq ($(shell command -v helm),)
	@echo "helm could not be found!"
	@echo "Please install helm!"
	@echo "Ex.: sudo snap install helm --classic"
else
	  helm upgrade --cleanup-on-fail \
	  --install $(RELEASE) jupyterhub/jupyterhub \
	  --namespace "$(NAMESPACE)" \
	  --create-namespace \
	  --version="$(VER)" \
	  --values "$(CONFIG_FILE)" \
	  --timeout 10m0s # Wait for pulling of large container images
endif

include .env
# Include auth section only if all necessary environment variables are defined
define AUTH_SECTION_TEMPLATE
auth:
  type: github
  github:
    clientId: "$(GITHUB_CLIENT_ID)"
    clientSecret: "$(GITHUB_CLIENT_SECRET)"
    callbackUrl: "http://$(JUPYTERHUB_IP)/hub/oauth_callback"
endef
# If all GitHub Oauth sections defined, include in template
AUTH_ENV_VARS = GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET JUPYTERHUB_IP
ifndef_any_of = $(filter undefined,$(foreach v,$(1),$(origin $(v))))
ifeq ($(call ifndef_any_of,$(AUTH_ENV_VARS)),)
$(CONFIG_FILE): export AUTH_SECTION := $(AUTH_SECTION_TEMPLATE)
endif
## Generate JupyterHub Helm chart configuration file
config.yaml: # Alias for auto-generated documentation
$(CONFIG_FILE): export ENV_DIR := /home/jovyan/.user_conda_envs/
$(CONFIG_FILE): export FASTAI_BOOK_ENV :=fastbook
$(CONFIG_FILE): export TEMPLATE_FILEPATH := config.TEMPLATE.yaml
$(CONFIG_FILE): TARGET_SPECIFIC_REQ_ENV_VARS := PROXY_SECRET # Fail if not defined
$(CONFIG_FILE): validate_req_env_vars
	export DOCKER_REPO=$(DOCKER_REPO); \
	export IMG_TAG=$(TAG); \
	envsubst <$(PROJECT_DIR)/$(TEMPLATE_FILEPATH) >$(PROJECT_DIR)/$(CONFIG_FILE)


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
export DESCRIPTION
.PHONY: help
help:
ifdef DESCRIPTION
	@echo "$$(tput bold)Description:$$(tput sgr0)" && echo "$$DESCRIPTION" && echo
endif
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
