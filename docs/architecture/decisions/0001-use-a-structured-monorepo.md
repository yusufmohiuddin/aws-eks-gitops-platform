# ADR-0001: Use a structured monorepo

- Status: Accepted
- Date: 2026-08-24
- Owners: Platform Engineering

## Context

The platform contains application code, AWS infrastructure, Kubernetes
packaging, GitOps environment state, observability configuration, and
operational documentation.

These components have different deployment lifecycles and security concerns,
but changes frequently span more than one component. The repository structure
must preserve ownership boundaries without making coordinated changes
unnecessarily difficult.

## Decision

Use one repository with explicit top-level boundaries for application,
infrastructure, platform configuration, documentation, and automation.

Path-based continuous integration workflows will validate only the components
affected by a change. Infrastructure application and environment promotion will
remain separate operations with independent approval controls.

Argo CD will reconcile only the declared GitOps paths. It will not deploy
directly from application source directories.

## Consequences

Benefits:

- Architecture and implementation remain discoverable in one location.
- Cross-component changes can be reviewed atomically.
- Shared policies and documentation have one authoritative home.
- Repository-level controls can enforce consistent engineering standards.

Tradeoffs:

- Access control cannot be isolated as strongly as it can across repositories.
- Workflow path filters and ownership rules must prevent unintended deployment.
- Repository history grows across several independently changing components.

The repository can be divided when team ownership, compliance requirements, or
release volume require stronger isolation. That change must preserve immutable
artifacts and pull-request-based environment promotion.

## Alternatives considered

### Separate repositories for every component

This provides stronger access isolation and independent release histories, but
adds coordination overhead before distinct teams or compliance boundaries
exist.

### Application and infrastructure only

This omits GitOps state and operational assets from the primary engineering
record and weakens end-to-end traceability.

## Verification

- Every deployable component has a documented owner and validation workflow.
- Workflow permissions and path filters are tested.
- Application builds cannot modify infrastructure.
- CI cannot deploy directly to the Kubernetes API.
- Argo CD reads only approved GitOps configuration paths.
