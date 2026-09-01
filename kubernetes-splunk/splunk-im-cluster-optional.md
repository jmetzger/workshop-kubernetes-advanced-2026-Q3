# Optional: Splunk im Cluster betreiben

Splunk lässt sich alternativ auch **im Cluster** selbst betreiben, über den offiziellen
Splunk Operator und eigene Custom Resources. Das ist der seltenere Weg (an einen Cluster
gebunden, zusätzlicher Operator- und Storage-Overhead), aber lehrreich, weil sichtbar wird,
was der Operator im Hintergrund automatisiert. Der Log-Forwarder ist in beiden Varianten
identisch — der einzige strukturelle Unterschied ist, ob der HEC-Aufruf (HTTP Event Collector)
die Cluster-Grenze verlässt oder nicht.

![Architektur: Log-Forwarder ist in beiden Varianten identisch, der Unterschied ist ob der HEC-Aufruf (HTTP Event Collector) die Cluster-Grenze verlässt](uebungen/screenshots/04-architektur-varianten.svg)

| Aspekt | 🟠 Extern (Hauptpfad) | 🔵 Im Cluster (optional) |
|---|---|---|
| Splunk läuft auf | eigenem Server / VM, unabhängig vom Cluster | Pod im selben Cluster wie die Workloads |
| Zusätzlich nötig | eigene Infrastruktur (VM, Terraform, Reverse-Proxy für TLS) | Splunk-Operator, CRDs, PVCs (Block-Storage) |
| Skaliert auf mehrere Cluster | ja — mehrere Cluster, ein Sammelbecken | nein — 1:1 an den Cluster gebunden |
| Lifecycle-Kopplung | entkoppelt — Cluster-Wartung stört Splunk nicht | Node-Upgrades/Drains im Cluster betreffen auch Splunk |
| Typisch für | Produktions-Logging, mehrere Teams/Cluster | Test-/Dev-Umgebungen, Kubernetes-native Teams |

Zusätzlich für die In-Cluster-Variante nötig:

- [ ] Splunk-Operator-CRDs — per `kubectl apply --server-side`, zu groß für Helm (>1 MB)
- [ ] Splunk Operator + Standalone-Chart — Helm-Repo `splunk.github.io/splunk-operator`, Lizenz per `SPLUNK_GENERAL_TERMS` akzeptieren
- [ ] Persistenter Storage — StorageClass mit Block-Storage, Standalone braucht getrennte Volumes für `/etc` und `/var`

Hands-on zur optionalen In-Cluster-Variante: [uebungen/10](uebungen/10-optional-splunk-operator-installieren.md)
bis [uebungen/14](uebungen/14-optional-aufraeumen-in-cluster.md).

Infrastruktur-Aufbau und Kosten: siehe [README](README.md).
