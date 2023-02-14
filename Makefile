SHELL := /bin/bash

export TERRAFORM_VERSION=1.3.8
export HELP_FILTER ?= help|lint|terraform|tflint|tfmodule
export README_TEMPLATE_FILE ?= $(BUILD_HARNESS_EXTENSIONS_PATH)/templates/README_gp.md.gotmpl
export README_DEPS ?= docs/targets.md docs/terraform.md

-include $(shell curl -sSL -o .build-harness-ext "https://gitlab.com/sr2c/build-harness-extensions/-/raw/main/Makefile.bootstrap"; echo .build-harness-ext)

## Lint Terraform code
lint:
	$(SELF) terraform/install terraform/get-modules terraform/lint terraform/validate tflint
