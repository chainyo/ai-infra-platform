## 1. Bootstrap directory and root Application manifest

- [x] 1.1 Create `bootstrap/` directory with a `root-application.yaml` ArgoCD Application manifest pointing to `clusters/dev/` as source, `argocd` namespace as destination, and automated sync with selfHeal enabled
- [x] 1.2 Verify `root-application.yaml` passes `kubectl --dry-run=client apply -f` without errors

## 2. Dev cluster declarations

- [x] 2.1 Create `clusters/dev/kustomization.yaml` using Kustomize format that lists only ArgoCD-related resources (no Layer 3 modules)
- [x] 2.2 Verify `kubectl kustomize clusters/dev/` produces valid YAML with no errors

## 3. Bootstrap script implementation

- [x] 3.1 Rewrite `script/bootstrap-cluster.sh` with a shebang, `set -euo pipefail`, and a guard that checks `KUBECONFIG` is set (exits non-zero with error to stderr if missing)
- [x] 3.2 Add Helm `argocd` namespace creation and `helm upgrade --install argo-cd oci://ghcr.io/argoproj/argo-helm/argo-cd` with a pinned chart version (`--version`) and `--create-namespace`
- [x] 3.3 Add `kubectl rollout status deployment/argo-cd-argocd-server -n argocd --timeout=300s` and `kubectl rollout status statefulset/argo-cd-argocd-application-controller -n argocd --timeout=300s` after Helm install
- [x] 3.4 Add `kubectl apply -f bootstrap/root-application.yaml` after ArgoCD is healthy
- [x] 3.5 Verify `shellcheck script/bootstrap-cluster.sh` passes with no errors or warnings

## 4. Verify script Layer 2 health checks

- [x] 4.1 Add a Layer 2 section to `script/verify-platform.sh` that checks the `argocd` namespace exists (exits non-zero with message if missing)
- [x] 4.2 Add a check that all pods in `argocd` namespace are in `Running` state
- [x] 4.3 Add a check that the `root` ArgoCD Application has sync status `Synced` and health status `Healthy` (exits non-zero with status details if not)
- [x] 4.4 Verify `shellcheck script/verify-platform.sh` passes with no errors or warnings

## 5. Promote specs to openspec/specs/

- [x] 5.1 Copy `openspec/changes/layer2-gitops-bootstrap/specs/argocd-bootstrap/spec.md` to `openspec/specs/argocd-bootstrap/spec.md`
- [x] 5.2 Copy `openspec/changes/layer2-gitops-bootstrap/specs/cluster-declarations/spec.md` to `openspec/specs/cluster-declarations/spec.md`
