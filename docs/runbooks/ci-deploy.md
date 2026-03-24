# Runbook: Deploy Workflow

**Workflow file:** `.github/workflows/deploy.yaml`
**Trigger:** Manual (`workflow_dispatch`) only

---

## What it does

| Job | Depends on | Purpose |
|---|---|---|
| `deploy` | — | `terraform apply` for `terraform/modules/hetzner-k3s`, uploads kubeconfig artifact |
| `bootstrap` | `deploy` | `script/bootstrap-cluster.sh` — installs ArgoCD, applies cluster kustomization |

---

## Deploy procedure

### Option A — Manual deploy (GitHub UI)

1. Navigate to **Actions → deploy → Run workflow**
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

### Option A — Re-apply a previous tag

If the new deployment is broken, re-apply a previously known-good repository
state manually:

```sh
git checkout v1.2.2           # Check out old code
cd terraform/modules/hetzner-k3s
export HCLOUD_TOKEN=<token>
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
terraform init
terraform apply -auto-approve
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
`kubeconfig-<tag>-<run-id>` with a **1-day TTL**.

Download via CLI:

```sh
gh run list --workflow=deploy.yaml --limit=5       # find the run ID
gh run download <run-id> --name kubeconfig-<tag>-<run-id>
```

The cluster API server endpoint is masked in workflow logs — retrieve it from the downloaded file.

---

## Secrets and variables required

| Name | Type | Used by |
|---|---|---|
| `HCLOUD_TOKEN` | Secret | `deploy` |
| `SSH_PRIVATE_KEY` | Secret | `deploy`, `bootstrap` |
| `SSH_PUBLIC_KEY` | Secret | `deploy` |
| `HZ_OBJECT_STORAGE_ACCESS_KEY` | Secret | `deploy` (backend) |
| `HZ_OBJECT_STORAGE_SECRET_KEY` | Secret | `deploy` (backend) |
| `CLUSTER_NAME` | Variable | `deploy` (default: `ai-infra-platform`) |
| `CLUSTER_LOCATION` | Variable | `deploy` (default: `hel1`) |

See [ci-secrets.md](./ci-secrets.md) for setup instructions.
