# Security Policy

## Reporting a vulnerability

Do not disclose suspected vulnerabilities through a public GitHub issue.

Report the affected component, reproduction conditions, potential impact, and
any known mitigations through GitHub private vulnerability reporting.

Do not include active credentials, account identifiers, private endpoints, or
other sensitive data in the report.

## Security model

This repository follows these controls:

- AWS access uses short-lived credentials issued through OpenID Connect.
- Static cloud credentials are not stored in GitHub.
- Infrastructure changes are reviewed and applied through controlled workflows.
- Container images are scanned and referenced using immutable identifiers.
- Kubernetes workloads run with restricted security contexts.
- Secrets are stored outside Git and synchronized at runtime.
- Dependencies and infrastructure definitions are continuously scanned.
- Security-relevant changes remain traceable through Git history.

## Supported versions

Security fixes are applied to the default branch. Released artifacts are
replaced with a new immutable version rather than modified in place.
