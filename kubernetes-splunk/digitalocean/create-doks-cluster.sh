#!/bin/bash
# Creates the DOKS cluster for the Splunk test setup (2 nodes, no HA control plane)
# Usage: ./create-doks-cluster.sh
# Requires DO_TOKEN in the environment (see .env.enc / security skill inject mechanism)

set -euo pipefail

REGION="fra1"
NODE_SIZE="s-2vcpu-4gb"
NODE_COUNT=2
K8S_VERSION="1.35" # adjust to latest stable: doctl kubernetes options versions
CLUSTER_NAME="splunk-training"

if [[ -z "${DO_TOKEN:-}" ]]; then
  echo "ERROR: DO_TOKEN nicht gesetzt."
  exit 1
fi

K8S_FULL_VERSION=$(doctl kubernetes options versions \
  | grep "^${K8S_VERSION}\." \
  | sort -V | tail -1 \
  | awk '{print $1}')

if [[ -z "$K8S_FULL_VERSION" ]]; then
  echo "==> Keine Version fuer ${K8S_VERSION}.x gefunden, verwende neueste verfuegbare Version"
  K8S_FULL_VERSION=$(doctl kubernetes options versions --no-header | sort -V | tail -1 | awk '{print $1}')
fi

echo "==> Erstelle DOKS Cluster ${CLUSTER_NAME}"
echo "==> Version: ${K8S_FULL_VERSION}  Node: ${NODE_SIZE} x${NODE_COUNT}  Region: ${REGION}  HA: false"

doctl kubernetes cluster create "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --version "${K8S_FULL_VERSION}" \
  --node-pool "name=${CLUSTER_NAME}-pool;size=${NODE_SIZE};count=${NODE_COUNT}" \
  --ha=false \
  --wait

echo ""
echo "==> Cluster laeuft. Naechster Schritt: ./download-kubeconfig-to-bastion.sh"
