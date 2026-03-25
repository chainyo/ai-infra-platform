# ci-deploy Specification

## Purpose
TBD - created by archiving change github-actions-cicd. Update Purpose after archive.
## Requirements
### Requirement: Production deploy workflow runs on main and on demand
The workflow SHALL trigger on every push to `main` and SHALL also support `workflow_dispatch` for operators.

#### Scenario: Push to main triggers production deploy
- **WHEN** a commit is pushed to `main`
- **THEN** the workflow SHALL start a deployment targeting the protected `production` environment

#### Scenario: Manual trigger via GitHub UI
- **WHEN** an operator triggers the deploy workflow via `workflow_dispatch`
- **THEN** the workflow SHALL start the same production deployment flow used on `main`

### Requirement: Deploy applies Layer 1 Terraform only when needed
The workflow SHALL detect whether `terraform/**` changed. When Terraform changes are present, it SHALL run `terraform init` and `terraform apply -auto-approve` for the target Hetzner module before any GitOps sync steps. When Terraform changes are absent, it SHALL skip Layer 1 apply.

#### Scenario: First-time provisioning
- **WHEN** the deploy workflow runs against a cluster that does not yet exist
- **THEN** `terraform apply` SHALL provision all resources (server, network, firewall) and output a kubeconfig

#### Scenario: App-only change skips Terraform
- **WHEN** a push to `main` changes `platform/`, `clusters/`, or `apps/` but does not change `terraform/`
- **THEN** the workflow SHALL skip `terraform apply`
- **AND** continue with GitOps reconciliation using kubeconfig exported from Terraform state

### Requirement: Deploy converges Terraform state before handoff
If the initial Terraform apply leaves a small amount of follow-up state convergence work, the workflow SHALL perform one additional reconciliation pass before proceeding to cluster bootstrap and GitOps sync.

#### Scenario: Follow-up Terraform convergence is needed
- **WHEN** an initial `terraform apply` succeeds but an immediate post-apply plan still exits with code `2`
- **THEN** the workflow SHALL run one additional `terraform apply`
- **AND** proceed only after Terraform state is converged or a hard error occurs

### Requirement: Deploy bootstraps the cluster after Layer 1 changes
When Terraform changes are applied, the workflow SHALL invoke `script/bootstrap-cluster.sh` using the kubeconfig output from Terraform, installing ArgoCD and applying the target cluster's `kustomization.yaml`.

#### Scenario: Bootstrap on a fresh cluster
- **WHEN** `bootstrap-cluster.sh` is run after first-time provisioning
- **THEN** ArgoCD SHALL be installed, the cluster kustomization SHALL be applied, and all Applications SHALL sync

#### Scenario: Bootstrap on an existing cluster
- **WHEN** `bootstrap-cluster.sh` is run on a cluster that already has ArgoCD
- **THEN** the script SHALL detect the existing installation and skip re-installation, applying only the kustomization diff

### Requirement: Deploy reconciles GitOps and verifies the platform on every run
Regardless of whether Terraform changed, the workflow SHALL export kubeconfig from Terraform state, sync ArgoCD Applications, and run `script/verify-platform.sh`.

#### Scenario: GitOps-only deploy succeeds
- **WHEN** the workflow runs with no Terraform changes
- **THEN** it SHALL still apply the root Application, sync all ArgoCD Applications, and verify the platform successfully

#### Scenario: Verification fails after sync
- **WHEN** the platform verification step fails after Terraform and/or ArgoCD reconciliation
- **THEN** the workflow SHALL exit non-zero and surface the failing verification step in logs

### Requirement: Deploy workflow requires explicit approval for production
The workflow SHALL use a GitHub Environment named `production` with required reviewers, so that the deploy job is gated on at least one human approval before applying to the long-lived production cluster.

#### Scenario: Deploy to production requires approval
- **WHEN** the deploy workflow targets the `production` environment
- **THEN** the deploy job SHALL pause at the environment gate and wait for a required reviewer to approve before proceeding

### Requirement: Deploy workflow uploads kubeconfig as a masked artifact
The workflow SHALL upload the kubeconfig generated or exported during deployment as a GitHub Actions artifact with a short TTL (1 day), masked in logs, so operators can retrieve it for manual debugging if needed.

#### Scenario: Kubeconfig is available after deploy
- **WHEN** the deploy workflow completes successfully
- **THEN** the kubeconfig SHALL be available as a downloadable artifact for 1 day, with the cluster endpoint and credentials masked in workflow logs
