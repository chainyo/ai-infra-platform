#!/usr/bin/env bash
# fetch-kubeconfig.sh — fetches and patches the k3s kubeconfig from a remote server.
# Called by the Terraform external data source in main.tf.
#
# Arguments:
#   $1 — server public IPv4 address
#   $2 — path to SSH private key
#
# Stdout: JSON object with a single "kubeconfig" key (required by the external data source).
# Stderr: diagnostic messages (ignored by Terraform, visible in debug output).
set -euo pipefail

SERVER_IP="$1"
KEY_PATH="$2"

# k3s writes the kubeconfig with 127.0.0.1 as the server address.
# Replace it with the public IP so the config is usable from outside the server.
REMOTE_CMD="sed 's|https://127.0.0.1:6443|https://${SERVER_IP}:6443|g' /etc/rancher/k3s/k3s.yaml"

KUBECONFIG=$(ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout=30 \
  -i "$KEY_PATH" \
  "root@${SERVER_IP}" \
  "$REMOTE_CMD")

# Emit as a JSON object for the Terraform external data source protocol.
echo "$KUBECONFIG" | python3 -c "
import json, sys
kubeconfig = sys.stdin.read()
print(json.dumps({'kubeconfig': kubeconfig}))
"
