## 1. Repository Foundations

- [ ] 1.1 Add `.yamllint.yaml` config file to the repo root with project-standard rules (2-space indent, 120-char line limit, no trailing spaces)
- [ ] 1.2 Create `.github/` directory structure: `workflows/` and `actions/` subdirectories
- [ ] 1.3 Document required GitHub secrets in `docs/runbooks/ci-secrets.md`: `HCLOUD_TOKEN`, `SSH_PRIVATE_KEY`, `HZ_OBJECT_STORAGE_ACCESS_KEY`, `HZ_OBJECT_STORAGE_SECRET_KEY`
- [ ] 1.4 Create Terraform backend config for Hetzner Object Storage in `terraform/hetzner-k3s/backend.tf`

## 2. PR Validation Workflow

- [ ] 2.1 Create `.github/workflows/pr-validation.yaml` with job triggers: `pull_request` on `opened`, `synchronize`, `reopened`
- [ ] 2.2 Add `terraform-fmt` job: checkout, setup Terraform, run `terraform fmt -check -recursive ./terraform`
- [ ] 2.3 Add `terraform-validate` job: init each changed module directory, run `terraform validate`, triggered only when `terraform/**` paths change
- [ ] 2.4 Add `terraform-plan` job: run `terraform plan -detailed-exitcode` for changed Layer 1 modules, post plan output as PR comment using `github-script`
- [ ] 2.5 Add `yaml-lint` job: install `yamllint`, run against all changed `.yaml`/`.yml` files using `yamllint -c .yamllint.yaml`
- [ ] 2.6 Add `k8s-validate` job: install `kubeconform`, run against changed manifests under `platform/`, `clusters/`, `apps/` with pinned Kubernetes schema version
- [ ] 2.7 Add `shellcheck` job: install `shellcheck`, run against all changed `.sh` files under `script/` and `.github/`
- [ ] 2.8 Add `paths` filters to each job so unrelated changes skip the relevant jobs
- [ ] 2.9 Add `concurrency` group with `cancel-in-progress: true` scoped to the PR number
- [ ] 2.10 Pin all third-party actions used in this workflow to full commit SHA

## 3. Live Deploy Workflow (push to main)

- [ ] 3.1 Create `.github/workflows/live-deploy.yaml` with trigger: `push` to `main`
- [ ] 3.2 Add `sync` job: decode `LIVE_CLUSTER_KUBECONFIG` secret to a temp file, run `argocd app sync --all --wait --timeout 300`
- [ ] 3.3 Add rollback step (runs `if: failure()`): detect degraded Applications via `argocd app list`, run `argocd app rollback <app>` for each
- [ ] 3.4 Add concurrency group scoped to `main` branch with `cancel-in-progress: false` (queue, don't cancel)
- [ ] 3.5 Ensure kubeconfig temp file is deleted at end of job (`if: always()`)
- [ ] 3.6 Add `LIVE_CLUSTER_KUBECONFIG` to required secrets list in `docs/runbooks/ci-secrets.md`
- [ ] 3.7 Pin all third-party actions to full commit SHA

## 4. Infra Smoke Test Workflow (daily cron)

- [ ] 4.1 Create `.github/workflows/infra-smoke-test.yaml` with trigger: `schedule: cron: '0 3 * * *'` (03:00 UTC = 04:00 CET)
- [ ] 4.2 Add `provision` job: `terraform init` (Hetzner Object Storage backend), `terraform apply -auto-approve`, capture kubeconfig output
- [ ] 4.3 Add `bootstrap` job (depends on `provision`): run `script/bootstrap-cluster.sh` with kubeconfig from previous job, wait for ArgoCD sync
- [ ] 4.4 Add `verify` job (depends on `bootstrap`): run `script/verify-platform.sh` against the ephemeral cluster
- [ ] 4.5 Add `destroy` job: `terraform destroy -auto-approve` with `if: always()` to ensure cleanup on success and failure
- [ ] 4.6 Create `script/verify-platform.sh` if it does not exist: check all expected pods are Running, ArgoCD Applications are Synced+Healthy
- [ ] 4.7 Pin all third-party actions to full commit SHA

- [ ] 5.1 Create `.github/workflows/deploy.yaml` with triggers: `workflow_dispatch` (environment input) and `push` on `v*.*.*` tags
- [ ] 5.2 Add environment selector input to `workflow_dispatch` with options: `staging`, `production`
- [ ] 5.3 Add `deploy` job: `terraform init`, `terraform apply -auto-approve` targeting Hetzner Layer 1 module
- [ ] 5.4 Add `bootstrap` job (depends on `deploy`): invoke `script/bootstrap-cluster.sh` with Terraform kubeconfig output
- [ ] 5.5 Configure GitHub Environment `production` with required reviewer protection rule
- [ ] 5.6 Upload masked kubeconfig as GitHub Actions artifact with 1-day TTL using `actions/upload-artifact`
- [ ] 5.7 Pin all third-party actions to full commit SHA

## 6. Dependency Review Workflow

- [ ] 6.1 Create `.github/workflows/dependency-review.yaml` with trigger: `pull_request` on `opened`, `synchronize`
- [ ] 6.2 Add `dependency-review` job using `actions/dependency-review-action` pinned to SHA, fail on HIGH+ CVEs
- [ ] 6.3 Set workflow permissions to `contents: read` only
- [ ] 6.4 Add a workflow-level check for non-SHA-pinned third-party actions in changed workflow files (grep-based or via `zizmor`)

## 7. Runbooks

- [ ] 7.1 Create `docs/runbooks/ci-pr-validation.md`: how to read plan output, re-trigger jobs, fix common lint failures
- [ ] 7.2 Create `docs/runbooks/ci-live-deploy.md`: how the ArgoCD sync + rollback works, how to recover if rollback also fails, how to manually re-trigger
- [ ] 7.3 Create `docs/runbooks/ci-infra-smoke-test.md`: how to monitor daily runs, check Hetzner for orphaned resources, how to manually trigger
- [ ] 7.4 Create `docs/runbooks/ci-deploy.md`: step-by-step deploy procedure, how to approve production gate, rollback steps (terraform destroy + re-apply previous tag)
- [ ] 7.5 Update root `README.md` to add CI status badges and link to the runbooks

## 8. Validation

- [ ] 8.1 Open a test PR with a deliberately unformatted Terraform file and verify `pr-validation` blocks it
- [ ] 8.2 Merge a passing PR to `main` and verify `live-deploy` syncs ArgoCD successfully
- [ ] 8.3 Manually trigger `infra-smoke-test` and verify end-to-end: provision → bootstrap → verify → destroy
- [ ] 8.4 Push a `v0.1.0` tag and verify the `deploy` workflow triggers and pauses at the production environment gate
- [ ] 8.5 Confirm no Hetzner resources are orphaned after infra-smoke-test completion (check Hetzner Cloud console)
