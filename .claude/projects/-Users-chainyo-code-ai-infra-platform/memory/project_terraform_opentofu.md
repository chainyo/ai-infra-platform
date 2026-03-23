---
name: terraform-opentofu-choice
description: The repo will be published as a GitHub template; users should be able to choose Terraform or OpenTofu as their IaC binary at setup time
type: project
---

When the repo is published as a GitHub template, let users choose between Terraform (HashiCorp, BSL 1.1) and OpenTofu (CNCF fork, MPL 2.0 open source) as their IaC binary.

**Why:** HashiCorp changed Terraform's license to BSL 1.1 (not open source) in Aug 2023; IBM acquired HashiCorp Apr 2024. OpenTofu is the CNCF-maintained open source fork, 100% HCL-compatible, drop-in replacement (`tofu` instead of `terraform`). The project owner prefers open source tooling but wants to give template users the choice.

**How to apply:** Do not migrate to OpenTofu unilaterally. When the "publish as template" milestone is reached, implement a toolchain-selection mechanism:
- Single CI variable (`TF_BINARY: terraform | tofu`) driving which GitHub Action is used
- `workstation-setup.md` covering both install paths
- Template questionnaire or setup script to set the preference
- The `.tf` files, provider configs, backend, and state format require zero changes either way
