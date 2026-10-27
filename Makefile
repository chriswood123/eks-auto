TF ?= tofu
TF_DIR := examples/basic

.PHONY: init plan apply destroy fmt validate kubeconfig

init:
	$(TF) -chdir=$(TF_DIR) init

plan:
	@test -d $(TF_DIR)/.terraform || $(TF) -chdir=$(TF_DIR) init
	$(TF) -chdir=$(TF_DIR) plan

apply:
	@test -d $(TF_DIR)/.terraform || $(TF) -chdir=$(TF_DIR) init
	$(TF) -chdir=$(TF_DIR) apply

destroy:
	$(TF) -chdir=$(TF_DIR) destroy

fmt:
	$(TF) fmt -recursive

validate:
	$(TF) -chdir=$(TF_DIR) validate

kubeconfig:
	$$($(TF) -chdir=$(TF_DIR) output -raw kubeconfig_command)
