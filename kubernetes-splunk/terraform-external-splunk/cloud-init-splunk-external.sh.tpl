#!/bin/bash
# Cloud-Init fuer die externe Splunk-Enterprise-VM (nativer Linux-Install, kein Docker/K8s).
# Wird von Terraform per templatefile() gerendert - ${splunk_admin_password} und
# ${splunk_hec_token} kommen aus TF_VAR_* Umgebungsvariablen (.env.enc), Claude sieht die
# Werte nie im Klartext.

set -e

DOMAIN="do.t3isp.de"
HOSTNAME_SHORT=$(hostname -s)

# ── SSH ───────────────────────────────────────────────────────────────────────
for CFG in /etc/ssh/sshd_config.d/50-cloud-init.conf \
           /etc/ssh/sshd_config.d/60-cloudimg-settings.conf; do
  [ -f "$CFG" ] && sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" "$CFG"
done
systemctl restart ssh

# ── Firewall: SSH, HTTP/HTTPS (Reverse-Proxy) und HEC (8088) offen,
#    Splunk-Web (8000) bleibt nur lokal auf dem Nginx-Host erreichbar ────────
# Hinweis zu HEC: Traffic aus Kubernetes-Pods (Cilium/DOKS) wird beim Verlassen
# des Clusters NICHT auf die Node-IP maskiert, wenn das Ziel eine private
# VPC-Adresse ist (nur bei oeffentlichen Zielen). Deshalb faellt hier die
# "sauberere" Variante (nur VPC-CIDR erlauben) aus - HEC ist bewusst oeffentlich
# erreichbar, abgesichert nur durch den Token. Fuer echten Produktionsbetrieb:
# Cilium-Masquerade-Konfiguration fixen oder eine DO Load Balancer/Cloud
# Firewall mit expliziten Node-IPs verwenden.
apt-get update -qq
apt-get install -y -qq ufw
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8088/tcp
ufw allow from ${vpc_cidr} to any port 8088 proto tcp
ufw --force enable

# ── Splunk Enterprise installieren ────────────────────────────────────────────
cd /tmp
wget -q "${splunk_deb_url}" -O splunk.deb
dpkg -i splunk.deb

# ── Admin-Passwort vorab setzen (user-seed.conf, von Splunk beim ersten Start
#    automatisch gehasht und dann ignoriert) ──────────────────────────────────
mkdir -p /opt/splunk/etc/system/local
cat > /opt/splunk/etc/system/local/user-seed.conf <<'SEED'
[user_info]
USERNAME = admin
PASSWORD = ${splunk_admin_password}
SEED
chmod 600 /opt/splunk/etc/system/local/user-seed.conf

# ── HEC vorkonfigurieren mit selbst gewaehltem Token (statt Splunk einen
#    zufaelligen generieren zu lassen) ────────────────────────────────────────
mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local
cat > /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf <<'HEC'
[http]
disabled = 0
enableSSL = 1
port = 8088

[http://k8s-forwarder]
disabled = 0
token = ${splunk_hec_token}
index = main
HEC

# ── Lizenz akzeptieren, starten, Boot-Start aktivieren ────────────────────────
# --run-as-root noetig: Splunk >=10 verweigert sonst den Start als root (kein
# dedizierter splunk-OS-User in diesem einfachen Testsetup).
/opt/splunk/bin/splunk start --accept-license --no-prompt --answer-yes --run-as-root
/opt/splunk/bin/splunk enable boot-start -user root --accept-license --no-prompt --answer-yes

date > /root/splunk-install-done

# ── DNS-Record registrieren (gleiches Muster wie die anderen Trainings-VMs) ──
cd /tmp
wget -q https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
mv doctl /usr/local/bin/
chmod +x /usr/local/bin/doctl

export HOME=/root
doctl auth init --access-token "${do_token}" || echo "doctl auth init failed"

PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
RECORD_ID=$(doctl compute domain records list "$DOMAIN" --format ID,Name --no-header | grep " $${HOSTNAME_SHORT}$" | awk '{print $1}')

if [ -n "$RECORD_ID" ]; then
  doctl compute domain records update "$DOMAIN" --record-id "$RECORD_ID" --record-data "$PUBLIC_IP"
else
  doctl compute domain records create "$DOMAIN" --record-type A --record-name "$HOSTNAME_SHORT" --record-data "$PUBLIC_IP" --record-ttl 300
fi

echo "DNS: $${HOSTNAME_SHORT}.$${DOMAIN} -> $PUBLIC_IP" >> /root/splunk-install-done

# ── Nginx als Reverse-Proxy vor Splunk Web (Port 8000 bleibt intern) mit
#    Let's-Encrypt-Zertifikat fuer die VM-Domain ─────────────────────────────
FQDN="$${HOSTNAME_SHORT}.$${DOMAIN}"
apt-get install -y -qq nginx certbot python3-certbot-nginx

# Unquoted Heredoc: $${FQDN} (von Bash expandiert), \$host etc. (escaped,
# bleiben als nginx-Variablen woertlich stehen statt von Bash expandiert zu werden)
cat > /etc/nginx/sites-available/splunk <<NGINX
server {
    listen 80;
    server_name $${FQDN};

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/splunk /etc/nginx/sites-enabled/splunk
nginx -t && systemctl reload nginx

# DNS braucht ggf. ein paar Sekunden, bis es auflösbar ist - certbot per HTTP-01
# Challenge braucht das schon beim ersten Versuch.
for _i in $(seq 1 12); do
  RESOLVED_IP=$(getent hosts "$${FQDN}" | awk '{print $1}')
  [ "$RESOLVED_IP" = "$PUBLIC_IP" ] && break
  sleep 5
done

certbot --nginx -d "$${FQDN}" --non-interactive --agree-tos -m "${admin_email}" --redirect \
  || echo "certbot fehlgeschlagen - DNS evtl. noch nicht propagiert, siehe uebungen/08-externe-splunk-vm.md"
