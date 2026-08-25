SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help app-check helm-check gitops-check image-build local-up local-verify local-down cloud-plan cloud-apply cloud-kubeconfig gitops-bootstrap cloud-verify cloud-destroy

help: ## Show available project commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "%-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

app-check: ## Run formatting, linting, typing, tests, and coverage
	cd application && uv run ruff format --check .
	cd application && uv run ruff check .
	cd application && uv run mypy src
	cd application && uv run pytest --cov=platform_reference_service --cov-fail-under=90

helm-check: ## Lint and verify rendered Helm chart behavior
	./scripts/helm-render-check.sh

gitops-check: ## Validate GitOps state, promotion safety, and observability rendering
	cd application && uv run pytest ../scripts/tests/test_update_image_digest.py
	./scripts/gitops-render-check.sh

image-build: ## Build the local reference service image
	docker build --tag platform-reference-service:local application

local-up: ## Build and deploy to a disposable local Kubernetes cluster
	./scripts/local-cluster-up.sh

local-verify: ## Verify the live local deployment and security context
	./scripts/local-cluster-verify.sh

local-down: ## Remove the Helm release and destroy the local cluster
	./scripts/local-cluster-down.sh

cloud-plan: ## Preview AWS development environment changes
	terraform -chdir=infrastructure/environments/dev plan

cloud-apply: ## Create or update the reviewed AWS development environment
	./scripts/cloud-apply.sh

cloud-kubeconfig: ## Configure kubectl for the provisioned EKS cluster
	./scripts/cloud-kubeconfig.sh

gitops-bootstrap: ## Install Argo CD and register approved applications
	./scripts/cloud-gitops-bootstrap.sh

cloud-verify: ## Verify infrastructure, GitOps, workload, metrics, and drift
	./scripts/cloud-verify.sh

cloud-destroy: ## Destroy the development environment after explicit confirmation
	./scripts/cloud-destroy.sh
