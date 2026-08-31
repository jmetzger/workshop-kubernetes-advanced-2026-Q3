#!/bin/bash
# Creates the bastion server for the Splunk training (client-splunk)
# Region: fra1, Size: s-4vcpu-8gb, Image: ubuntu-24-04-x64
# DNS A-Record client-splunk.do.t3isp.de is created automatically by cloud-init (Phase 11)

set -euo pipefail

REGION="fra1"
SIZE="s-4vcpu-8gb"
IMAGE="ubuntu-24-04-x64"
NAME="client-splunk"
SSH_KEY_ID="53105908" # claude-code-testing (~/.ssh/id_ed25519_nopass)
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="${TEMPLATE_DIR}/cloud-init-bastion.sh.template"

if [[ -z "${DO_TOKEN:-}" ]]; then
  echo "ERROR: DO_TOKEN nicht gesetzt."
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template nicht gefunden: $TEMPLATE"
  exit 1
fi

# Substitute placeholder and store in temp file
TMPFILE="$HOME/cloud-init-bastion-current.sh"
trap 'rm -f "$TMPFILE"' EXIT
sed -e "s|__DO_TOKEN__|${DO_TOKEN}|g" "$TEMPLATE" > "$TMPFILE"

echo "==> Erstelle Bastion-Droplet ${NAME}"
echo "==> Region: $REGION  Size: $SIZE  Image: $IMAGE"

doctl compute droplet create "$NAME" \
  --region "$REGION" \
  --size "$SIZE" \
  --image "$IMAGE" \
  --ssh-keys "$SSH_KEY_ID" \
  --user-data-file "$TMPFILE" \
  --wait

echo ""
echo "==> Droplet erstellt (cloud-init läuft im Hintergrund ~5 Min)."
echo "==> Status prüfen:"
echo "    doctl compute droplet list --format Name,PublicIPv4,Status | grep ${NAME}"
echo "    doctl compute domain records list do.t3isp.de | grep ${NAME}"
echo ""
echo "==> SSH testen (nach ~2 Min):"
echo "    ssh -i ~/.ssh/id_ed25519_nopass root@${NAME}.do.t3isp.de"
