## Why

Layer 1 provisions a bare k3s cluster and outputs a kubeconfig, but nothing is installed inside the cluster. Without Layer 2, the CI smoke test's `bootstrap` and `verify` steps run stub scripts that do nothing, leaving the platform incomplete and the smoke test misleading. Layer 2 is the bridge: it takes the kubeconfig produced by Terraform and hands control of the cluster to ArgoCD, after which everything inside the cluster is GitOps-managed.

## What Changes

- **New** `script/bootstrap-cluster.sh` — replaces the current stub with a real idempotent script that installs ArgoCD via Helm and applies the root Application manifest
- **New** `bootstrap/` directory — holds the root ArgoCD Application YAML (applied once, then ArgoCD takes over)
- **New** `clusters/` directory — per-cluster kustomize declarations; starts with a `dev` cluster that activates ArgoCD as its only platform module
- **Modified** `script/verify-platform.sh` — adds Layer 2 health checks (ArgoCD pods Running, root Application Synced + Healthy, no Degraded applications)

## Capabilities

### New Capabilities

- `argocd-bootstrap`: Idempotent shell script that installs ArgoCD via a pinned Helm chart into a bare k3s cluster, applies the root ArgoCD Application (App of Apps), and waits until ArgoCD is fully healthy. Completes within 5 minutes. Covers the bootstrap script, the `bootstrap/` YAML, and Layer 2 additions to the verify script.
- `cluster-declarations`: Kustomize-based per-cluster directory structure under `clusters/`. Each cluster folder declares which platform modules are enabled. The `dev` cluster is the reference target used by CI; it enables only the `gitops` core module (ArgoCD itself). Uses a base/overlay pattern for future production cluster overrides.

### Modified Capabilities

*(none — no existing spec-level requirements are changing)*

## Impact

- `script/bootstrap-cluster.sh` — rewritten from stub
- `script/verify-platform.sh` — extended with Layer 2 checks
- New top-level directories: `bootstrap/`, `clusters/`
- CI smoke test (`infra-smoke-test.yaml`) bootstrap and verify steps will now exercise real infrastructure
- No impact on Layer 1 Terraform modules, Layer 3 platform modules, or GitHub Actions workflow files (they already call the correct script paths)
