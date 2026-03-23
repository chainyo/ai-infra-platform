## ADDED Requirements

### Requirement: Cluster directory structure follows base/overlay pattern

The `clusters/` directory SHALL use a Kustomize base/overlay structure. Each cluster directory (`clusters/<name>/`) SHALL contain a `kustomization.yaml` that lists the platform resources the cluster enables. The `dev` cluster SHALL be the first and reference cluster, used by the CI smoke test.

#### Scenario: Valid dev cluster kustomization

- **WHEN** `kubectl kustomize clusters/dev/` is executed
- **THEN** it produces valid Kubernetes manifest YAML with no errors

#### Scenario: New cluster inherits from dev base

- **WHEN** a new `clusters/prod/` overlay is created that extends `clusters/dev/`
- **THEN** it can override individual resource values without duplicating the base declarations

### Requirement: Dev cluster activates only the gitops module at Layer 2

The `clusters/dev/kustomization.yaml` SHALL reference only the ArgoCD (gitops) module at Layer 2 completion. It SHALL NOT reference any Layer 3 platform modules (networking, observability, storage, AI tooling). Layer 3 modules are added to `clusters/dev/` as part of their own implementation changes.

#### Scenario: Dev cluster resources at Layer 2 completion

- **WHEN** the `clusters/dev/` directory is inspected after Layer 2 is implemented
- **THEN** it contains an ArgoCD Application pointing to the gitops platform module (or a self-referential ArgoCD configuration)
- **AND** it does NOT contain references to networking, observability, storage, or AI modules

### Requirement: Root Application manifest is stored in bootstrap/

The `bootstrap/` directory SHALL contain `root-application.yaml`, an ArgoCD `Application` manifest that points to `clusters/dev/` as the source of truth for the dev cluster. This manifest SHALL be applied by the bootstrap script and SHALL NOT be managed by ArgoCD itself (it is the entry point for GitOps, not a product of it).

#### Scenario: Root Application references correct repository and path

- **WHEN** `bootstrap/root-application.yaml` is inspected
- **THEN** `spec.source.repoURL` points to the canonical HTTPS URL of this repository
- **AND** `spec.source.path` is `clusters/dev`
- **AND** `spec.destination.server` is `https://kubernetes.default.svc` (in-cluster)
- **AND** `spec.destination.namespace` is `argocd`

#### Scenario: Root Application uses automated sync policy

- **WHEN** `bootstrap/root-application.yaml` is inspected
- **THEN** `spec.syncPolicy.automated` is configured
- **AND** `selfHeal: true` is set so ArgoCD corrects drift automatically

### Requirement: All version references are pinned

The ArgoCD Helm chart version used in the bootstrap script SHALL be pinned to a specific semantic version (e.g., `7.x.y`). It SHALL NOT use floating tags like `latest` or version ranges. This enables Renovate to detect and propose updates automatically.

#### Scenario: Renovate detects ArgoCD chart version

- **WHEN** Renovate scans `script/bootstrap-cluster.sh`
- **THEN** it identifies the pinned ArgoCD Helm chart version
- **AND** opens a PR when a newer chart version is available
