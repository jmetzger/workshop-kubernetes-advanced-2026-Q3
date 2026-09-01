# Kubernetes an einen externen Splunk-Server anbinden

Splunk Enterprise als zentrales Log-Sammelbecken für einen (oder mehrere) DigitalOcean
Kubernetes (DOKS) Cluster. Im Vordergrund steht die Anbindung an einen **externen**
Splunk-Server — Splunk läuft auf eigener Infrastruktur außerhalb des Clusters, der Cluster
selbst enthält nur einen leichten Log-Forwarder. Der Betrieb von Splunk **im Cluster** (über
den Splunk Operator) wird zusätzlich als optionaler Anhang gezeigt.

Konzeptioneller Hintergrund: [UEBERSICHT.md](UEBERSICHT.md). Vergleich beider Wege:
[splunk-im-cluster-optional.md](splunk-im-cluster-optional.md).

## Architektur

![Architektur: Splunk extern auf eigener VM](uebungen/screenshots/05-architektur-variante-b.svg)

Splunk läuft nativ (kein Docker) auf einer eigenen VM außerhalb des Clusters, per Terraform +
Cloud-Init aufgesetzt (`terraform-external-splunk/`). Der Cluster enthält nur einen leichten
Log-Forwarder (DaemonSet), der Container-Logs und Kubernetes-Events per HEC (HTTP Event
Collector) an die externe Splunk-Instanz überträgt. Die Web-UI ist direkt per HTTPS
erreichbar (Nginx-Reverse-Proxy mit Let's-Encrypt-Zertifikat), kein SSH-Tunnel nötig.

## Kosten

- Splunk selbst läuft mit dem kostenlosen `.deb`-Paket von Splunk Enterprise — 60 Tage
  Trial-Lizenz, danach automatisch Splunk Free License (500 MB/Tag, Single-User).
- DOKS-Control-Plane ist kostenlos, es fallen nur Kosten für die Worker-Nodes, den
  Bastion-Server und die externe Splunk-VM an (siehe `digitalocean/` und
  `terraform-external-splunk/`).
- Nichts vergessen aufzuräumen: [uebungen/05-aufraeumen.md](uebungen/05-aufraeumen.md).

## Infrastruktur aufbauen

Cluster + Bastion (gemeinsam genutzt für externe und optionale In-Cluster-Variante),
ausgeführt aus dem Projekt-Root (`DO_TOKEN` wird automatisch aus `.env.enc` geladen):

```
cd digitalocean
./create-doks-cluster.sh
./create-bastion.sh
./download-kubeconfig-to-bastion.sh
```

Details: `digitalocean/`.

## Agenda

**Hauptpfad — Splunk extern anbinden**

  1. Cluster-Zugang
     * [Zugang zum bestehenden Cluster](uebungen/01-cluster-zugang.md)
  2. Externe Splunk-Instanz
     * [Externe Splunk-VM per Terraform aufsetzen](uebungen/02-externe-splunk-vm.md)
  3. Log-Forwarding
     * [Log-Forwarder an die externe Splunk-VM anbinden](uebungen/03-forwarder-an-externe-splunk.md)
  4. Log-Suche & Troubleshooting
     * [Abstürzenden Pod über Splunk debuggen (CrashLoopBackOff)](uebungen/04-log-suche-crashloop-debugging.md)
  5. Aufräumen
     * [Aufräumen](uebungen/05-aufraeumen.md)

**Optionaler Anhang — Splunk im Cluster betreiben**

  10. Splunk Operator
     * [Splunk Operator installieren](uebungen/10-optional-splunk-operator-installieren.md)
  11. Splunk Standalone
     * [Splunk Standalone (S1) deployen](uebungen/11-optional-standalone-splunk-deployen.md)
     * [Auf die Splunk-Web-UI zugreifen](uebungen/12-optional-splunk-ui-zugriff-in-cluster.md)
  13. Log-Forwarding (In-Cluster)
     * [Log-Forwarder installieren](uebungen/13-optional-log-forwarding-in-cluster.md)
  14. Aufräumen (In-Cluster-Variante)
     * [Aufräumen](uebungen/14-optional-aufraeumen-in-cluster.md)

## Automatisierung (optional)

Für die optionale In-Cluster-Variante gibt es zusätzlich eine automatisierte Installation
per Terraform (`terraform/` deployt CRDs, Splunk Operator und eine Splunk-Standalone-Instanz
in einem Rutsch, als Alternative zu den manuellen Schritten 10-11):

```
cd terraform
terraform init
terraform apply -var="kubeconfig_path=/tmp/config"
```

## Struktur

```
digitalocean/             DOKS-Cluster + Bastion-Server anlegen (doctl + cloud-init)
terraform-external-splunk/ Hauptpfad: externe Splunk-VM per Terraform + Cloud-Init
terraform/                 Optional: automatisierte In-Cluster-Installation via Helm-Provider
splunk-manifests/          Helm-Values für Splunk-Chart und Log-Forwarder
uebungen/                  Schritt-für-Schritt-Übungen (Hauptpfad + optionaler Anhang)
```
