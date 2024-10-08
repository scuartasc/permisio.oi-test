# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Make will use bash instead of sh
SHELL := /usr/bin/env bash
ROOT := ${CURDIR}

# create/delete/validate is for CICD
.PHONY: create
create:
	$(ROOT)/create.sh
.PHONY: delete
teardown:
	$(ROOT)/teardown.sh

.PHONY: validate
validate:
	${ROOT}/validate.sh

# All is the first target in the file so it will get picked up when you just run 'make' on its own
lint: check_shell check_shebangs check_python check_golang check_terraform check_docker check_base_files check_headers check_trailing_whitespace

# The .PHONY directive tells make that this isn't a real target and so
# the presence of a file named 'check_shell' won't cause this target to stop
# working
.PHONY: check_shell
check_shell:
	@source test/make.sh && check_shell

.PHONY: ci
ci: verify-header

.PHONY: verify-header
verify-header:
	python test/verify_boilerplate.py
	@echo "\n Test passed - Verified all file Apache 2 headers"

.PHONY: setup-project
setup-project:
	# Enables the Google Cloud APIs needed
	./enable-apis.sh
	# Runs the generate-tfvars.sh
	./generate-tfvars.sh

.PHONY: tf-apply
tf-apply:
	# Downloads the terraform providers and applies the configuration
	cd terraform && terraform init && terraform apply

.PHONY: tf-destroy
tf-destroy:
	# Downloads the terraform providers and applies the configuration
	cd terraform && terraform destroy


.PHONY: clean-up
clean-up:
	./remove_manifests.sh

.PHONY: check_python
check_python:
	@source test/make.sh && check_python

.PHONY: check_golang
check_golang:
	@source test/make.sh && golang

.PHONY: check_terraform
check_terraform:
	@source test/make.sh && check_terraform

.PHONY: check_docker
check_docker:
	@source test/make.sh && docker

.PHONY: check_base_files
check_base_files:
	@source test/make.sh && basefiles

.PHONY: check_shebangs
check_shebangs:
	@source test/make.sh && check_bash

.PHONY: check_trailing_whitespace
check_trailing_whitespace:
	@source test/make.sh && check_trailing_whitespace

.PHONY: check_headers
check_headers:
	@echo "Checking file headers"
	@python3.7 test/verify_boilerplate.py