#!/usr/bin/env bash
# bootstrap-cluster.sh — Install ArgoCD and apply the root kustomization.
#
# This script is a placeholder. Full implementation is part of Layer 2
# (clusters/ + platform/ GitOps bootstrap).
#
# Expected environment:
#   KUBECONFIG — path to the cluster kubeconfig (set by the caller)
#
# Usage:
#   KUBECONFIG=/path/to/kubeconfig bash script/bootstrap-cluster.sh

set -euo pipefail

echo "bootstrap-cluster.sh: Layer 2 bootstrap not yet implemented."
echo "This placeholder will be replaced when clusters/ and platform/ are added."
echo ""
echo "KUBECONFIG=${KUBECONFIG:-<not set>}"
echo ""
echo "Next steps for Layer 2:"
echo "  1. Install ArgoCD into the cluster"
echo "  2. Apply the root kustomization from clusters/<target>/kustomization.yaml"
echo "  3. Wait for all ArgoCD Applications to reach Synced+Healthy"

exit 0
