# Runbook: Infra Drift Check

**Workflow file:** `.github/workflows/infra-drift-check.yaml`  
**Trigger:** Push to `main`, daily schedule, or manual (`workflow_dispatch`)

---

## What it does

Runs `terraform plan -detailed-exitcode` against the long-lived Hetzner state for
`terraform/modules/hetzner-k3s`.

This answers one question: is Layer 1 still aligned with `main`?

| Exit code | Meaning | Workflow result |
|---|---|---|
| `0` | Infra is aligned | Success |
| `2` | Drift or unapplied Terraform changes detected | Failure |
| `1` | Terraform/backend error | Failure |

The workflow uploads the full plan output as an artifact:
`infra-drift-plan-<run-id>`.

---

## When to use it

- After merging Terraform changes to `main`
- On a schedule, to detect infrastructure drift even when no code changed
- Before running the manual `deploy` workflow, if you want to confirm whether Layer 1 is out of sync

---

## Interpreting a failure

### Drift detected

If the workflow fails with drift, the repository and production Terraform state
do not match.

Typical causes:

- a Terraform change landed in `main` but `deploy` has not been run yet
- repository variables or SSH key inputs changed
- the long-lived cluster was modified or recreated outside the normal workflow

Recommended action:

```sh
gh workflow run deploy.yaml
```

Then verify the new `deploy` run completes successfully.

### Terraform error

If the workflow fails before producing a valid plan, look for:

- S3 backend credential errors
- Hetzner API credential errors
- invalid or missing repository variables

Download the plan artifact and inspect the workflow logs for the failing step.

---

## Manual trigger

**GitHub UI:** Actions → `infra-drift-check` → Run workflow  

**CLI:**

```sh
gh workflow run infra-drift-check.yaml
```

---

## Secrets and variables required

| Name | Type | Used by |
|---|---|---|
| `HCLOUD_TOKEN` | Secret | Terraform provider auth |
| `SSH_PRIVATE_KEY` | Secret | plan input parity |
| `SSH_PUBLIC_KEY` | Secret | plan input parity |
| `HZ_OBJECT_STORAGE_ACCESS_KEY` | Secret | backend auth |
| `HZ_OBJECT_STORAGE_SECRET_KEY` | Secret | backend auth |
| `CLUSTER_NAME` | Variable | target cluster name |
| `CLUSTER_LOCATION` | Variable | target datacenter |

See [ci-secrets.md](./ci-secrets.md) for setup instructions.
