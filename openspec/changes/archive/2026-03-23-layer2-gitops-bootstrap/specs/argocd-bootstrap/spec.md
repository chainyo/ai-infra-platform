## ADDED Requirements

### Requirement: Bootstrap script installs ArgoCD via Helm

`script/bootstrap-cluster.sh` SHALL install ArgoCD into the cluster using `helm upgrade --install` with a pinned chart version. The installation SHALL be idempotent — running the script more than once on the same cluster MUST NOT produce an error or leave the cluster in a broken state.

#### Scenario: First-time installation on a bare cluster

- **WHEN** `bootstrap-cluster.sh` is executed against a bare k3s cluster with `KUBECONFIG` set
- **THEN** ArgoCD is installed in the `argocd` namespace
- **AND** all ArgoCD pods (server, application-controller, repo-server, redis) reach `Running` state within 300 seconds

#### Scenario: Idempotent re-run on an already-bootstrapped cluster

- **WHEN** `bootstrap-cluster.sh` is executed a second time against a cluster where ArgoCD is already installed
- **THEN** the script exits with code 0
- **AND** ArgoCD resources are unchanged (no restart, no deletion)

#### Scenario: Missing KUBECONFIG env var

- **WHEN** `bootstrap-cluster.sh` is executed without `KUBECONFIG` set
- **THEN** the script exits with a non-zero exit code
- **AND** an error message identifying the missing variable is printed to stderr

### Requirement: Bootstrap script applies the root Application

After installing ArgoCD, `script/bootstrap-cluster.sh` SHALL apply the root ArgoCD Application manifest from `bootstrap/root-application.yaml` using `kubectl apply`. The root Application SHALL be applied idempotently.

#### Scenario: Root Application created on first bootstrap

- **WHEN** `bootstrap-cluster.sh` completes successfully on a bare cluster
- **THEN** an ArgoCD Application named `root` exists in the `argocd` namespace
- **AND** it references `clusters/dev/` in this repository as its source

#### Scenario: Root Application already exists on re-run

- **WHEN** `bootstrap-cluster.sh` is executed a second time and the root Application already exists
- **THEN** `kubectl apply` completes without error (no "already exists" error)
- **AND** the root Application is unchanged if no manifest changes were made

### Requirement: Bootstrap script waits for ArgoCD to be healthy

`script/bootstrap-cluster.sh` SHALL wait for ArgoCD's `argo-cd-argocd-server` deployment and `argo-cd-argocd-application-controller` StatefulSet to reach a ready state before exiting. The wait SHALL time out after 300 seconds and exit non-zero if the timeout is reached.

#### Scenario: ArgoCD becomes healthy within timeout

- **WHEN** ArgoCD pods are scheduled and all images pull successfully
- **THEN** the bootstrap script waits and exits with code 0 after ArgoCD is healthy

#### Scenario: ArgoCD fails to become healthy within 300 seconds

- **WHEN** image pull or pod scheduling takes longer than 300 seconds
- **THEN** the script exits with a non-zero exit code
- **AND** a timeout error message is printed to stderr

### Requirement: Bootstrap script passes shellcheck

`script/bootstrap-cluster.sh` SHALL produce no errors or warnings when checked with `shellcheck`. This is validated by the `shellcheck` job in `pr-validation.yaml`.

#### Scenario: PR validation on bootstrap script change

- **WHEN** a pull request modifies `script/bootstrap-cluster.sh`
- **THEN** the `shellcheck` CI job passes with exit code 0

### Requirement: Verify script reports ArgoCD health

`script/verify-platform.sh` SHALL include Layer 2 health checks that verify ArgoCD is running and its root Application is healthy. These checks SHALL run after the existing Layer 1 node readiness checks.

#### Scenario: Healthy cluster passes Layer 2 verification

- **WHEN** `verify-platform.sh` is executed against a bootstrapped cluster
- **THEN** the script confirms the `argocd` namespace exists
- **AND** confirms all ArgoCD pods are in `Running` state
- **AND** confirms the root Application is `Synced` and `Healthy`
- **AND** exits with code 0

#### Scenario: ArgoCD namespace missing

- **WHEN** `verify-platform.sh` is executed against a cluster with no `argocd` namespace
- **THEN** the script exits with a non-zero exit code
- **AND** prints a message identifying the missing namespace

#### Scenario: Root Application is Degraded

- **WHEN** `verify-platform.sh` is executed and the root Application status is `Degraded`
- **THEN** the script exits with a non-zero exit code
- **AND** prints the Application name and its current sync/health status
