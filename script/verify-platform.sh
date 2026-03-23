#!/usr/bin/env bash
# verify-platform.sh — Verify that the provisioned cluster is healthy.
#
# Layer 1 checks: cluster connectivity, node readiness, system pod health.
# Layer 2+ checks (ArgoCD Applications) will be added when the platform is
# bootstrapped.
#
# Usage:
#   KUBECONFIG=/path/to/kubeconfig bash script/verify-platform.sh
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

set -euo pipefail

KUBECTL_TIMEOUT="30s"
NODE_READY_TIMEOUT="300s"

echo "==> [1/3] Cluster connectivity"
kubectl cluster-info --request-timeout="${KUBECTL_TIMEOUT}"
echo ""

echo "==> [2/3] Node readiness"
kubectl wait node --all --for=condition=Ready --timeout="${NODE_READY_TIMEOUT}"
echo "    All nodes Ready."
echo ""

echo "==> [3/3] kube-system pod health"
NOT_READY=$(kubectl get pods -n kube-system \
  --field-selector='status.phase!=Running,status.phase!=Succeeded' \
  --no-headers 2>/dev/null | grep -v '^$' || true)
if [ -n "$NOT_READY" ]; then
  echo "::error::One or more kube-system pods are not healthy:"
  echo "${NOT_READY}"
  exit 1
fi
echo "    All kube-system pods healthy."
echo ""

echo "Platform verification passed."
