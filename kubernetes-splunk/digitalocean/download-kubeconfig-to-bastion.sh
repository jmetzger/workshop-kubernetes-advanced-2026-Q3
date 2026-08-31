#!/bin/bash
# Downloads the kubeconfig for the splunk-training DOKS cluster and copies it
# to the bastion (client-splunk) at /tmp/config.
# Usage: ./download-kubeconfig-to-bastion.sh

set -euo pipefail

CLUSTER_NAME="splunk-training"
BASTION="${BASTION:-client-splunk.do.t3isp.de}"
BASTION_USER="${BASTION_USER:-root}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_nopass}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -z "${DO_TOKEN:-}" ]]; then
  echo "ERROR: DO_TOKEN nicht gesetzt."
  exit 1
fi

LOCAL_FILE="${TMP_DIR}/config"

echo "==> Lade kubeconfig fuer ${CLUSTER_NAME}..."
doctl kubernetes cluster kubeconfig show "${CLUSTER_NAME}" > "$LOCAL_FILE"

echo "==> Kopiere kubeconfig nach ${BASTION}:/tmp/config..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
  "$LOCAL_FILE" "${BASTION_USER}@${BASTION}:/tmp/config"

echo "==> Fertig. Test: ssh -i ${SSH_KEY} ${BASTION_USER}@${BASTION} 'KUBECONFIG=/tmp/config kubectl get nodes'"
