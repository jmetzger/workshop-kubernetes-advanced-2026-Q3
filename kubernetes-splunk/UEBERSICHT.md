# Splunk mit Kubernetes verbinden

Architekturüberblick: was eine Splunk-Instanz braucht, um Daten aus einem
Kubernetes-Cluster zu bekommen. Im Mittelpunkt steht hier die Anbindung an einen
**externen** Splunk-Server — das ist der in der Praxis übliche Weg. Der Betrieb von Splunk
**innerhalb** des Clusters ist als optionale Variante ausgelagert:
[splunk-im-cluster-optional.md](splunk-im-cluster-optional.md).

## Was ist Splunk

Eine Plattform zum Einsammeln, Durchsuchen und Korrelieren von Maschinendaten — Logs,
Metriken, Events. Schema-on-read: Rohdaten werden zuerst indexiert, die Struktur wird erst
bei der Suche extrahiert.

| | |
|---|---|
| **Gegründet** | 2003, San Francisco — der Name kommt von „spelunking“, dem Erforschen von Höhlen |
| **Lizenz** | Proprietär. Trial 60 Tage, danach automatisch Free License (500 MB/Tag, Single-User) |
| **Typische Daten** | App-Logs, Syslog, Security-Events, Kubernetes-Events, Metriken via HEC (HTTP Event Collector) |
| **Abfragesprache** | SPL (Search Processing Language) — mächtiger als reine Volltextsuche |

## Wie kann ich Splunk betreiben (Architektur)

Splunk laesst sich als **Standalone**-Instanz (eine Instanz uebernimmt Indexer, Search Head
und Web-UI gleichzeitig), als **verteiltes System** (separate Indexer-Cluster,
Search-Head-Cluster, Lizenz-Manager), als **Cloud-Service** (Splunk Cloud Platform, gehostet
von Splunk) oder **in Kubernetes** (via Splunk Operator) betreiben.

Fuer das Training arbeiten wir mit Splunk Standalone. Der Server ist bereits eingerichtet
und erreichbar unter https://splunk-external.do.t3isp.de.

## Die Anbindung: Splunk extern, Kubernetes liefert nur zu

Der Kernpunkt dieser Anbindung: Splunk läuft **außerhalb** des Kubernetes-Clusters, auf
eigener Infrastruktur (dediziertem Server oder, wie hier zum Üben, einer einzelnen VM). Der
Cluster selbst enthält nur einen leichten Log-Forwarder (DaemonSet), der Container-Logs und
Kubernetes-Events einsammelt und per HEC (HTTP Event Collector, Port 8088) an die externe
Splunk-Instanz überträgt.

![Architektur: Splunk extern auf eigener VM](uebungen/screenshots/05-architektur-variante-b.svg)

Das hat drei praktische Vorteile gegenüber Splunk im Cluster:

- **Skaliert auf mehrere Cluster** — eine externe Splunk-Instanz kann Daten aus beliebig
  vielen Clustern gleichzeitig einsammeln, statt 1:1 an einen Cluster gebunden zu sein
- **Entkoppelter Lifecycle** — Node-Upgrades, Drains oder ein kompletter Cluster-Ausfall
  betreffen die bereits gesendeten Logs nicht, sie liegen sicher außerhalb
- **Kein Operator, keine PVCs im Cluster** — der Cluster selbst bleibt schlank, die
  Splunk-spezifische Komplexität (Storage, Lifecycle, Lizenz) liegt vollständig auf der
  externen Seite

Die technischen Bausteine der externen Anbindung im Detail:

- **HEC aktiviert + Token** — HTTP Event Collector auf Port `8088`, Token wird bei der
  externen VM selbst gewählt (per Terraform-Variable), nicht von Splunk generiert
- **Log-Forwarder als DaemonSet** — Splunk OpenTelemetry Collector, 1 Pod pro Node, liest
  `/var/log/pods/*/*.log` und schickt sie über HEC (HTTP Event Collector) nach außen
- **Netzwerkpfad Forwarder → HEC (HTTP Event Collector)** — Firewall/VPC-Routing der externen VM muss den
  Pod-Traffic aus dem Cluster durchlassen; Pod-Traffic wird beim Verlassen des Clusters auf
  die Node-IP maskiert, das VPC-CIDR muss das beruecksichtigen
- **Reverse-Proxy + TLS-Zertifikat** — Web-UI selbst bleibt intern (Port 8000 gesperrt),
  nginx terminiert HTTPS mit Let's-Encrypt-Zertifikat auf 80/443
- **Eigene Server-Infrastruktur** — VM per Terraform/Cloud-Init, natives
  Splunk-Enterprise-Paket (.deb), kein Docker, kein Kubernetes-Operator nötig

## Hands-on: externe Anbindung

Schritt-für-Schritt-Übungen zur externen Variante:

1. [Zugang zum bestehenden Cluster](uebungen/01-cluster-zugang.md)
2. (Optional) [Externe Splunk-VM per Terraform aufsetzen](uebungen/02-externe-splunk-vm.md)
3. [Log-Forwarder an die externe Splunk-VM anbinden](uebungen/03-forwarder-an-externe-splunk.md)
4. [Log-Suche und CrashLoopBackOff-Debugging](uebungen/04-log-suche-crashloop-debugging.md)
5. [Aufräumen](uebungen/05-aufraeumen.md)

Welche Splunk-Menuepunkte davon in der Uebung tatsaechlich vorkommen (und welche bewusst
aussen vor bleiben, weil sie den Betrieb von Splunk selbst statt die Kubernetes-Anbindung
betreffen): [menues-und-ihre-funktion.md](menues-und-ihre-funktion.md).
