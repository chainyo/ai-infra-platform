## Context

After `terraform apply`, a bare k3s cluster exists on Hetzner Cloud. The only thing running is `kube-system`. The CI smoke test calls `script/bootstrap-cluster.sh` (currently a no-op stub), then `script/verify-platform.sh` (currently checks only node readiness). Layer 2 must turn that bare cluster into a GitOps-managed cluster by installing ArgoCD and handing control to it.

The handoff pattern is: Terraform → kubeconfig → bootstrap script → ArgoCD owns everything inside the cluster. Once ArgoCD is running, the root Application tells ArgoCD to watch `clusters/dev/` in this repository. Any change merged to `main` that touches `clusters/dev/` is automatically reconciled into the cluster.

Constraint: the CI smoke test has an implicit total runtime budget of ~10–20 minutes. The bootstrap step must complete in under 5 minutes on a CX22 (2 vCPU, 4 GB RAM).

## Goals / Non-Goals

**Goals:**
- ArgoCD installed idempotently in the cluster via a pinned Helm chart
- Root Application (App of Apps) applied so ArgoCD self-manages `clusters/dev/`
- Bootstrap script passes `shellcheck` and exits non-zero on any failure
- Verify script reports ArgoCD health as part of its Layer 2 checks
- `dev` cluster declaration exists as the reference target for CI

**Non-Goals:**
- Installing any platform modules (networking, observability, AI tooling) — those are Layer 3
- Multi-cluster orchestration — Layer 2 only needs to work for one cluster at a time
- ArgoCD RBAC, SSO, or UI customisation — defaults are sufficient for now
- High availability ArgoCD — single-node k3s doesn't benefit from HA

## Decisions

### 1. Helm for ArgoCD installation, not raw manifests

**Decision:** Install ArgoCD using `helm upgrade --install` with `--create-namespace`.

**Rationale:** Pinned chart version (`7.x`) gives reproducible installs. `helm upgrade --install` is idempotent by design — running it twice is safe. Upgrading to a new ArgoCD version is a one-line version bump. Raw `kubectl apply -f` of upstream manifests is not idempotent (field manager conflicts) and harder to version-pin reliably.

**Alternatives considered:**
- `kubectl apply -f` of upstream install YAML — not idempotent, no version management
- ArgoCD operator — too much complexity for a single-node dev cluster

### 2. App of Apps pattern via a `bootstrap/root-application.yaml`

**Decision:** Apply one `Application` manifest via `kubectl apply` during bootstrap. This Application points ArgoCD at `clusters/dev/` in the repository. Everything else is declared there.

**Rationale:** The root Application is the only resource that cannot be managed by ArgoCD itself (you need ArgoCD running to apply it). Keeping it in `bootstrap/` signals clearly that it is applied once by the bootstrap script, not reconciled continuously. All subsequent resources are declared in `clusters/dev/` and owned by ArgoCD.

**Alternatives considered:**
- Applying all manifests imperatively — defeats the purpose of GitOps; ArgoCD drift detection would not apply
- Using ArgoCD's ApplicationSet — overkill for a single dev cluster at this stage

### 3. Kustomize base/overlay for cluster declarations

**Decision:** `clusters/dev/kustomization.yaml` is a Kustomize base that lists resources. Future production clusters use overlays that patch values.

**Rationale:** Kustomize is already the standard for GitOps overlays in ArgoCD. The base/overlay pattern lets production clusters inherit `dev` declarations and override only what differs (e.g., replica counts, resource limits). ArgoCD natively understands Kustomize — no additional tooling needed.

**Alternatives considered:**
- Helm values files per cluster — heavier, requires a chart wrapper around each module
- Plain YAML per cluster — no inheritance, high duplication as clusters multiply

### 4. Wait loop in bootstrap script, not external timeout

**Decision:** The bootstrap script polls `kubectl rollout status` and `argocd app wait` (via `kubectl wait`) with a fixed timeout (300 seconds). It does not rely on the CI job's timeout.

**Rationale:** Fail fast with a clear error message from the script itself. CI job-level timeouts produce generic "job cancelled" messages; a script-level timeout can print diagnostics before exiting. 300 seconds is conservative for a 4 GB RAM node pulling ~200 MB of ArgoCD images.

**Alternatives considered:**
- Relying solely on the CI job timeout — poor error messages, no diagnostics
- Sleeping fixed intervals — flaky; image pull time varies

### 5. No ArgoCD auth for this public repository

**Decision:** The root Application uses `repoURL: https://github.com/chainyo/ai-infra-platform` with no credentials. ArgoCD connects anonymously over HTTPS.

**Rationale:** The repository is public. No secrets need to be injected into manifests or the bootstrap script for the repo connection. Platform module secrets (e.g., Hetzner token for external-dns) are Layer 3 concerns.

## Risks / Trade-offs

**[Risk] Image pull slowness on first bootstrap** → ArgoCD pulls ~200 MB of images on a fresh node. Mitigation: 300-second wait timeout is generous; if hit in practice, consider a pre-pull step or switching to a CX32 for smoke tests.

**[Risk] Helm chart version pinned may fall behind** → Renovate is already configured in the repo and will open PRs to bump pinned versions. No manual tracking needed.

**[Risk] Bootstrap idempotency relies on Helm's idempotency** → `helm upgrade --install` is idempotent for Helm-managed resources, but any manually applied resources (e.g., root Application) need `kubectl apply` (not `kubectl create`) to avoid "already exists" errors. Script uses `apply` throughout.

**[Risk] ArgoCD sync may fail if `clusters/dev/` references Layer 3 resources not yet created** → The `dev` cluster declaration initially references only ArgoCD itself (the gitops module). Layer 3 modules are added only when their platform module directories exist. No forward references.
