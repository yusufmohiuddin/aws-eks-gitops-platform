# Contributing

## Change workflow

1. Create a focused branch from `main`.
2. Implement one coherent change.
3. Run the relevant local validation commands.
4. Open a pull request describing the purpose, risk, and verification evidence.
5. Review generated infrastructure or deployment plans before approval.
6. Merge only after required checks succeed.

Direct changes to protected branches are not part of the delivery workflow.

## Commit messages

Use concise imperative messages with a Conventional Commit prefix:

- `feat:` introduces a capability
- `fix:` corrects incorrect behavior
- `docs:` changes documentation
- `test:` adds or updates verification
- `refactor:` restructures code without changing behavior
- `build:` changes build or dependency configuration
- `ci:` changes automation
- `chore:` performs repository maintenance

Example commit message: `feat: add private EKS worker node groups`

## Pull requests

A pull request must explain:

- What changed
- Why the change is required
- How it was verified
- Security or operational implications
- Rollback considerations

Generated Terraform plans must not contain credentials or sensitive data.
