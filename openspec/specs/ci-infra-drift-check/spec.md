# ci-infra-drift-check Specification

## Purpose
TBD - created during implementation. Update Purpose if needed.

## Requirements
### Requirement: Production infrastructure drift is checked automatically

The repository SHALL provide a workflow that runs `terraform plan -detailed-exitcode` against the long-lived Hetzner cluster state and reports whether Layer 1 is aligned with the repository.

#### Scenario: No drift is present

- **WHEN** the drift-check workflow runs against the production Terraform state and the repository matches the deployed infrastructure
- **THEN** `terraform plan` exits with code `0`
- **AND** the workflow exits successfully

#### Scenario: Drift or unapplied Terraform changes are present

- **WHEN** the drift-check workflow runs and `terraform plan -detailed-exitcode` exits with code `2`
- **THEN** the workflow SHALL fail
- **AND** it SHALL publish the plan output as a workflow artifact
- **AND** it SHALL instruct operators to run the deploy workflow to reconcile Layer 1

### Requirement: Drift check is available on schedule and on demand

The infrastructure drift workflow SHALL run on a schedule and SHALL also support manual triggering via `workflow_dispatch`.

#### Scenario: Scheduled drift check runs

- **WHEN** the scheduled trigger fires
- **THEN** the workflow SHALL run a production-state Terraform plan without requiring a code change

#### Scenario: Operator triggers a manual drift check

- **WHEN** an operator runs the workflow via `workflow_dispatch`
- **THEN** the workflow SHALL execute the same production-state Terraform plan used by the scheduled check
