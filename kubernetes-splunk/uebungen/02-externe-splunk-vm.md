# Uebung 2 (Optional): Externe Splunk-VM per Terraform aufsetzen

## Status

Die Splunk-VM ist bereits eingerichtet und wird vom Trainer zur Verfuegung gestellt.

## Hintergrund

Splunk laeuft in dieser Uebung bewusst **ausserhalb** des Kubernetes-Clusters, als zentrales
Sammelbecken auf eigener Infrastruktur: der Cluster selbst enthaelt spaeter nur einen
leichten Forwarder, Splunk laeuft auf dedizierter Infrastruktur (oder eben, wie hier zum
Ueben, auf einer einzelnen VM) und kann theoretisch Daten aus mehreren Clustern gleichzeitig
einsammeln. Das ist der in der Praxis uebliche Weg, Splunk mit Kubernetes zu verbinden -
mehr dazu in der [Architektur-Uebersicht](../UEBERSICHT.md).

Diese Uebung baut Splunk **nativ** (kein Docker, kein Operator) auf einer eigenen
DigitalOcean-VM per Terraform + Cloud-Init auf.

## Schritt 1: Secrets vorbereiten

Zwei Werte werden gebraucht, beide **selbst gewaehlt statt von Splunk generiert** - das ist
der Vorteil eines IaC-Ansatzes: der Trainer/Teilnehmer legt Admin-Passwort und HEC-Token
selbst fest, bevor die VM ueberhaupt existiert, und muss sie hinterher nicht aus einem Secret
extrahieren.

Im Projekt-Root, im Terminal (nicht im Chat!):

```
cat >> .env << 'EOF'
TF_VAR_splunk_admin_password=<eigenes Passwort, min. 8 Zeichen>
TF_VAR_splunk_hec_token=<eigene UUID, z.B. Ausgabe von: uuidgen>
EOF
```

Danach in `.env.enc` verschluesseln (siehe Skill `security`) und `.env` loeschen.

## Schritt 2: Terraform anwenden

```
cd terraform-external-splunk
terraform init
terraform plan -var="do_token=$DO_TOKEN" -out=tfplan
terraform apply tfplan
```

`do_token` kommt bewusst per `-var` aus der schon vorhandenen `DO_TOKEN`-Variable (nicht
noch einmal separat gespeichert) - `splunk_admin_password` und `splunk_hec_token` werden
automatisch als `TF_VAR_*` aus `.env.enc` injiziert.

Output zeigt Public-/Private-IP und die naechsten Schritte.

## Schritt 3: Warten auf Cloud-Init

Installation von Splunk Enterprise (~1,3 GB Download + Setup) dauert einige Minuten.

```
ssh -i ~/.ssh/id_ed25519_nopass root@splunk-external.do.t3isp.de "cloud-init status"
```

Erwartete Ausgabe nach Abschluss: `status: done`.

## Schritt 4: Splunk-Status pruefen

```
ssh -i ~/.ssh/id_ed25519_nopass root@splunk-external.do.t3isp.de "/opt/splunk/bin/splunk status"
```

Erwartete Ausgabe: `splunkd is running`.

## Schritt 5: Auf die Web-UI zugreifen

Vor der Splunk-Instanz liegt ein Nginx-Reverse-Proxy mit echtem Let's-Encrypt-Zertifikat -
direkter HTTPS-Zugriff ohne SSH-Tunnel:

```
https://splunk-external.do.t3isp.de
```

Login mit `admin` + dem Passwort aus Schritt 1. Port 8000 selbst (Splunk Web direkt) bleibt
in der Firewall gesperrt - nur Nginx auf 80/443 darf durch, Nginx proxied intern zu
`127.0.0.1:8000`.

**Sicherheitshinweis:** Damit ist das Splunk-Web-Login oeffentlich im Internet erreichbar
(nur durch das Passwort geschuetzt, kein 2FA/Lockout). Fuer eine reine Teststellung
akzeptabel, in Produktion wuerde man zusaetzlich IP-Allowlisting, ein VPN oder mindestens
Fail2ban einsetzen.

## Schritt 6: HEC pruefen

Der HTTP Event Collector (Port 8088) ist die Schnittstelle, ueber die der Log-Forwarder in
der naechsten Uebung Daten anliefert. Kurzer Check von aussen (`curl` gegen den HEC-Endpoint,
Antwort `Token disabled/required` ist hier bereits ein gutes Zeichen - der Port antwortet):

```
curl -k https://splunk-external.do.t3isp.de:8088/services/collector/health
```
