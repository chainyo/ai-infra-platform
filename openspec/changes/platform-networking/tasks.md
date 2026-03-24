## 1. Terraform — Disable k3s built-in Traefik

- [ ] 1.1 Add `--disable=traefik` to the k3s install command in `terraform/modules/hetzner-k3s/`
- [ ] 1.2 Verify `terraform plan` for the hetzner-k3s module shows no unexpected changes beyond the install command update

## 2. Platform Directory Structure

- [ ] 2.1 Create `platform/networking/` directory with a top-level `kustomization.yaml` that references `traefik/` and `cert-manager/` sub-paths
- [ ] 2.2 Create `platform/networking/traefik/kustomization.yaml` listing `application.yaml`
- [ ] 2.3 Create `platform/networking/cert-manager/kustomization.yaml` listing `application.yaml` and `issuers-application.yaml`
- [ ] 2.4 Create `platform/networking/cert-manager/issuers/kustomization.yaml` listing `cluster-issuer.yaml`

## 3. Traefik ArgoCD Application

- [ ] 3.1 Create `platform/networking/traefik/application.yaml` — ArgoCD Application targeting the `traefik` Helm chart from `https://helm.traefik.io/traefik`, installed into the `traefik` namespace, with chart version pinned to a specific semver
- [ ] 3.2 Configure Helm values in the Application to use `hostPort` mode (ports 80 and 443) suitable for single-node k3s

## 4. cert-manager ArgoCD Applications

- [ ] 4.1 Create `platform/networking/cert-manager/application.yaml` — ArgoCD Application targeting the `cert-manager` Helm chart from `https://charts.jetstack.io`, installed into the `cert-manager` namespace, with chart version pinned, and `installCRDs: true` set
- [ ] 4.2 Create `platform/networking/cert-manager/issuers-application.yaml` — ArgoCD Application targeting `platform/networking/cert-manager/issuers/`, configured to sync after the cert-manager Helm Application so `ClusterIssuer` resources are only applied after the CRDs exist
- [ ] 4.3 Create `platform/networking/cert-manager/issuers/cluster-issuer.yaml` with two `ClusterIssuer` resources: `letsencrypt-staging` (staging ACME endpoint) and `letsencrypt-prod` (production ACME endpoint), both using HTTP-01 solver with `traefik` ingress class
- [ ] 4.4 Set `spec.acme.email` in both `ClusterIssuer` resources to a documented placeholder literal (not a Secret reference), with an inline comment stating operators must replace it before production use

## 5. Cluster Declaration Update

- [ ] 5.1 Add `../../platform/networking` to the `resources` list in `clusters/ai-infra-platform/kustomization.yaml`
- [ ] 5.2 Run `kubectl kustomize clusters/ai-infra-platform/` locally and confirm it produces valid YAML with Traefik and cert-manager Application manifests included

## 6. Verification Script

- [ ] 6.1 Extend `script/verify-platform.sh` to check that the `traefik` Deployment in namespace `traefik` has at least 1 ready replica
- [ ] 6.2 Extend `script/verify-platform.sh` to check that `cert-manager`, `cert-manager-webhook`, and `cert-manager-cainjector` Deployments in namespace `cert-manager` each have at least 1 ready replica
- [ ] 6.3 Confirm `shellcheck` passes on the updated `script/verify-platform.sh`

## 7. CI Smoke Test Compatibility

- [ ] 7.1 Review `.github/workflows/infra-smoke-test.yaml` — confirm it calls `script/verify-platform.sh` and will pick up the new networking checks automatically
- [ ] 7.2 Confirm the smoke-test workflow passes `--disable=traefik` via the updated Terraform module (no direct workflow changes needed if the Terraform change in task 1.1 is sufficient)
- [ ] 7.3 ⚠️ Flag: if `infra-smoke-test.yaml` needs changes (e.g., to wait longer for cert-manager CRDs), update it and note the change here
