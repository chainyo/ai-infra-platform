# Runbook: Production Deploy Workflow

**Workflow file:** `.github/workflows/deploy.yaml`
**Trigger:** Push to `main` and manual (`workflow_dispatch`)

---

## What it does

| Job | Depends on | Purpose |
|---|---|---|
| `deploy` | — | Unified production deploy: conditionally applies Terraform, bootstraps if needed, syncs ArgoCD, verifies platform health |

---

## Deploy procedure

Every push to `main` triggers the production deploy workflow automatically.

The workflow detects whether `terraform/**` changed:

- If Terraform changed: it runs Layer 1 apply first, then bootstraps the cluster, then syncs ArgoCD and verifies the platform.
- If Terraform did not change: it skips Layer 1 apply and reconciles the cluster using Terraform state + ArgoCD only.

### Manual deploy (GitHub UI)

1. Navigate to **Actions → deploy-production → Run workflow**
2. Click **Run workflow**

The workflow always targets the `production` environment and pauses at the
deployment gate until a required reviewer approves.

---

## Approving the production gate

When a `production` deploy is queued:

1. Open the workflow run in **Actions**
2. Click the yellow **Review deployments** banner
3. Check the **production** checkbox
4. Add an optional comment and click **Approve and deploy**

Only users listed in the `production` environment's **Required reviewers** setting can approve.

---

## Configuring the `production` GitHub Environment

This is a one-time setup step:

1. Go to **Settings → Environments**
2. Click **New environment**, name it `production`
3. Under **Deployment protection rules**, enable **Required reviewers**
4. Add at least one reviewer (yourself or a team)
5. Save

---

## Rollback procedure

### Option A — Revert and redeploy

If the new deployment is broken, revert the bad commit on `main` and let the
same workflow reconcile back to the previous state:

```sh
git revert <bad-commit-sha>
git push origin main
```

### Option B — Destroy and re-provision

```sh
cd terraform/modules/hetzner-k3s
terraform destroy -auto-approve
# Then trigger the deploy workflow again after the rollback is ready
```

---

## Retrieving the kubeconfig after deploy

The `deploy` job uploads the kubeconfig as a GitHub Actions artifact named
`kubeconfig-<ref>-<run-id>` with a **1-day TTL**.

Download via CLI:

```sh
gh run list --workflow=deploy.yaml --limit=5       # workflow file
gh run download <run-id> --name kubeconfig-<ref>-<run-id>
```

The cluster API server endpoint is masked in workflow logs — retrieve it from the downloaded file.

---

## Secrets and variables required

| Name | Type | Used by |
|---|---|---|
| `HCLOUD_TOKEN` | Secret | `deploy` |
| `SSH_PRIVATE_KEY` | Secret | `deploy` |
| `SSH_PUBLIC_KEY` | Secret | `deploy` |
| `HZ_OBJECT_STORAGE_ACCESS_KEY` | Secret | `deploy` (backend/state) |
| `HZ_OBJECT_STORAGE_SECRET_KEY` | Secret | `deploy` (backend/state) |
| `CLUSTER_NAME` | Variable | `deploy` (default: `ai-infra-platform`) |
| `CLUSTER_LOCATION` | Variable | `deploy` (default: `hel1`) |
| `K3S_VERSION` | Variable | Optional version pin passed to Terraform |

See [ci-secrets.md](./ci-secrets.md) for setup instructions.
