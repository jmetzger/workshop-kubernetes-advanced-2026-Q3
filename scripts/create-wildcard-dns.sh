#!/bin/bash
# Legt einen Wildcard-DNS-Record *.<dein-name>.do.t3isp.de auf die angegebene
# IP (DigitalOcean-DNS) - oder aktualisiert ihn, falls er schon existiert.
# Wird in der Traefik/Letsencrypt-Uebung verwendet.
#
# Usage:    create-wildcard-dns.sh <dein-name> <ip>
# Beispiel: create-wildcard-dns.sh tln5 165.22.73.43
#
# Token kommt aus /etc/training-dns.env (DO_DNS_TOKEN=..., stellt der
# Trainer bereit) oder aus einer bereits gesetzten Umgebungsvariable.
set -euo pipefail

NAME="${1:?Usage: create-wildcard-dns.sh <dein-name> <ip>}"
IP="${2:?Usage: create-wildcard-dns.sh <dein-name> <ip>}"
DOMAIN="do.t3isp.de"
API="https://api.digitalocean.com/v2/domains/$DOMAIN/records"

[ -f /etc/training-dns.env ] && source /etc/training-dns.env
: "${DO_DNS_TOKEN:?DO_DNS_TOKEN nicht gesetzt (fehlt /etc/training-dns.env?)}"

AUTH="Authorization: Bearer $DO_DNS_TOKEN"

# Existiert der Wildcard-Record schon? Dann nur die IP aktualisieren.
# (|| true: grep liefert Exit 1, wenn es noch keinen Record gibt - das ist ok)
EXISTING_ID=$(curl -sf -H "$AUTH" "$API?type=A&name=*.$NAME.$DOMAIN" \
  | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)

if [ -n "$EXISTING_ID" ]; then
  curl -sf -X PUT -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"data\":\"$IP\"}" "$API/$EXISTING_ID" >/dev/null
  echo "OK: *.$NAME.$DOMAIN aktualisiert -> $IP"
else
  curl -sf -X POST -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"type\":\"A\",\"name\":\"*.$NAME\",\"data\":\"$IP\",\"ttl\":300}" \
    "$API" >/dev/null
  echo "OK: *.$NAME.$DOMAIN angelegt -> $IP"
fi

echo "Pruefen mit:  dig +short irgendwas.$NAME.$DOMAIN"
echo "(Achtung: Namen erst NACH dem Anlegen abfragen - sonst Negative-Caching)"
