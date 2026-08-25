SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help app-check helm-check image-build local-up local-verify local-down

help: ## Show available project commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "%-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

app-check: ## Run formatting, linting, typing, tests, and coverage
	cd application && uv run ruff format --check .
	cd application && uv run ruff check .
	cd application && uv run mypy src
	cd application && uv run pytest --cov=platform_reference_service --cov-fail-under=90

helm-check: ## Lint and verify rendered Helm chart behavior
	./scripts/helm-render-check.sh

image-build: ## Build the local reference service image
	docker build --tag platform-reference-service:local application

local-up: ## Build and deploy to a disposable local Kubernetes cluster
	./scripts/local-cluster-up.sh

local-verify: ## Verify the live local deployment and security context
	./scripts/local-cluster-verify.sh

local-down: ## Remove the Helm release and destroy the local cluster
	./scripts/local-cluster-down.sh
