# Runbook: Live Deploy

**Workflow file:** `.github/workflows/live-deploy.yaml`
**Trigger:** Every push to `main`

---

## What it does

Deploys platform changes (Layers 2–4: clusters, platform, apps) to the permanent live demo cluster by
triggering an ArgoCD sync. It reads the live cluster kubeconfig from Terraform state so the workflow
tracks cluster replacements automatically.

| Step | Purpose |
|---|---|
| Terraform init | Connects to the production Terraform backend |
| Export kubeconfig | Reads the live cluster kubeconfig from Terraform state into `/tmp/kubeconfig` |
| Install ArgoCD CLI | Downloads the pinned ArgoCD CLI binary |
| Install kubectl | Provides kubeconfig-aware Kubernetes access for Argo CD core mode |
| Configure core access | Sets the kubeconfig namespace to `argocd`, then runs `argocd login localhost --core` |
| Apply root Application | Re-applies `bootstrap/root-application.yaml` so the live cluster follows the current GitOps entrypoint path |
| Sync all Applications | Lists Applications with `argocd app list --core -o name`, then runs `argocd app sync <app> --core` followed by `argocd app wait <app> --core --sync --health --timeout 300` |
| Rollback (on failure) | Detects degraded Applications and rolls each back to the last healthy revision |
| Remove kubeconfig | Deletes `/tmp/kubeconfig` — always runs, even on failure |

Expected runtime: **1–3 minutes** (sync) + up to 5 minutes for health checks.

---

## How ArgoCD sync works

The workflow uses Argo CD CLI **core mode**, which talks directly to the
Kubernetes API using the kubeconfig exported from Terraform state instead of
opening an Argo CD API session.

It first loads the kubeconfig from the production Terraform state:

```sh
terraform -chdir=terraform/modules/hetzner-k3s init
terraform -chdir=terraform/modules/hetzner-k3s output -raw kubeconfig > /tmp/kubeconfig
```

It first prepares core access:

```sh
kubectl config set-context --current --namespace=argocd
argocd login localhost --core
kubectl apply -f bootstrap/root-application.yaml
```

Then it syncs each Application:

```sh
argocd app list --core -o name
# Then, for each application:
argocd app sync <app> --core
argocd app wait <app> --core --sync --health --timeout 300
```

- `argocd login localhost --core` configures the CLI to use Kubernetes auth instead of an Argo CD API token.
- `kubectl apply -f bootstrap/root-application.yaml` keeps the root Application aligned with the repository's current cluster declaration path.
- `argocd app list --core -o name` enumerates every Application registered with the ArgoCD instance.
- `argocd app sync <app> --core` starts reconciliation for that Application.
- `argocd app wait <app> --core --sync --health --timeout 300` blocks until the Application is `Synced` and `Healthy`.
- `--timeout 300` means the wait step fails if the Application is not healthy within 5 minutes.
- This avoids storing a separate Argo CD credential in GitHub secrets.

On success the workflow exits 0 and the cluster is up to date.

---

## How automatic rollback works

If the sync step exits non-zero, the rollback step runs (`if: failure()`):

1. Lists all Applications via `argocd app list --core -o json`.
2. Filters for Applications in `Degraded` health state.
3. Runs `argocd app rollback <app> --core` for each degraded Application.

ArgoCD rollback reverts the Application to the last known-good revision stored in its history.
After rollback the workflow exits non-zero — the deploy failed, but the cluster is stable again.

---

## Manually re-triggering

After fixing the commit that caused the failure, push or merge to `main` to trigger a new run automatically.

To trigger without a new commit:

**GitHub UI:** Actions → live-deploy → Re-run all jobs

**CLI:**

```sh
gh workflow run live-deploy.yaml
```

---

## Recovery: rollback also fails

If the rollback step itself exits non-zero, the cluster is in an unknown state and requires manual
intervention.

### Step 1 — check Application status

```sh
export KUBECONFIG=~/.kube/ai-infra-platform.yaml
kubectl config set-context --current --namespace=argocd
argocd login localhost --core
argocd app list --core
```

Identify which Application is `Degraded`.

### Step 2 — inspect the Application

```sh
argocd app get <app-name> --show-operation --core
```

Look at the `Message` field under `Operation State` for the root cause.

### Step 3 — manual rollback

```sh
# Roll back to a specific revision (list history first)
argocd app history <app-name> --core
argocd app rollback <app-name> <revision-id> --core
```

### Step 4 — hard reset (last resort)

If rollback is not available (e.g. the repository itself is broken):

```sh
# Force-sync from a known-good commit
argocd app set <app-name> --revision <good-commit-sha> --core
argocd app sync <app-name> --force --core
```

### Step 5 — re-enable auto-sync

After manually stabilising the cluster, re-enable auto-sync if it was disabled:

```sh
argocd app set <app-name> --sync-policy automated --core
```

---

## Secrets required by this workflow

| Secret | Used by |
|---|---|
| `HZ_OBJECT_STORAGE_ACCESS_KEY` | Terraform backend access |
| `HZ_OBJECT_STORAGE_SECRET_KEY` | Terraform backend access |

See [ci-secrets.md](./ci-secrets.md) for setup instructions.
