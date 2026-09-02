# Uebung 3: Log-Forwarder an die externe Splunk-VM anbinden

## Hintergrund

![Warum ein Log-Forwarder: der Weg eines Log-Eintrags](screenshots/06-forwarder-ablauf.svg)

Diese Uebung installiert den **Splunk OpenTelemetry Collector** als DaemonSet und richtet
ihn auf den HEC-Endpoint der externen VM aus Uebung 2 aus.

<details>
<summary>Ausfuehrlicher Text (optional)</summary>

Container-Logs landen standardmaessig nur temporaer auf dem Node (stdout/stderr, von
containerd rotiert). Nach einem Pod-Neustart oder Node-Wechsel sind sie weg. Ein Forwarder
liest sie laufend ein und schickt sie ueber HEC (HTTP Event Collector) an Splunk, bevor sie
verloren gehen.

Da der HEC-Token beim Aufsetzen der VM selbst gewaehlt wurde (nicht von Splunk generiert),
muss er hier nicht erst aus einem Kubernetes-Secret extrahiert werden. Er wird vom Trainer
bekannt gegeben - wer die VM in Uebung 2 selbst aufgesetzt hat, hat ihn in der eigenen `.env`.

</details>

## Schritt 1: Arbeitsverzeichnis anlegen

Alle Dateien dieser Uebung landen in einem eigenen Verzeichnis, die folgenden Schritte
werden von dort ausgefuehrt:

```
cd
mkdir -p helm-values/splunk-otel
cd helm-values/splunk-otel
```

## Schritt 2: Token in eine Secret-Values-Datei eintragen

Den Token **nicht** per `--set` auf der Kommandozeile uebergeben (landet sonst in der
Bash-History und ggf. in `helm history`), sondern in eine eigene, kleine YAML-Datei
schreiben. Diese Datei bleibt nur lokal auf dem Bastion und ist die einzige Stelle, an
der der Token im Klartext steht:

```
nano hec-token-values.yml
```

Inhalt:

```
splunkPlatform:
  token: <HEC-Token - gibt der Trainer bekannt; bei selbst aufgesetzter VM: TF_VAR_splunk_hec_token aus Uebung 2 Schritt 1>
```

## Schritt 3: Collector-Konfiguration als Values-Datei anlegen

Der Rest der Konfiguration ist nicht geheim und kommt in eine zweite Values-Datei.
Den folgenden Block als Ganzes ins Terminal kopieren - `$(whoami)` ersetzt die Shell
dabei automatisch durch den eigenen Bastion-Username. Der dient als eindeutige
Cluster-Kennung: alle Teilnehmer senden an dieselbe Splunk-Instanz in denselben Index,
und ueber das Feld `k8s.cluster.name`, das der Forwarder aus `clusterName` erzeugt und
an jedes Event anhaengt, lassen sich die eigenen Daten spaeter wieder herausfiltern:

```
cat > collector-values.yml << EOF
clusterName: $(whoami)
splunkPlatform:
  # HEC-Endpoint der externen Splunk-VM aus Uebung 2
  endpoint: "https://splunk-external.do.t3isp.de:8088/services/collector"
  index: main
  # HEC (Port 8088) nutzt Splunks eigenes, selbstsigniertes Zertifikat -
  # das Let's-Encrypt-Zertifikat gilt nur fuer die Web-UI hinter Nginx
  insecureSkipVerify: true
EOF
cat collector-values.yml
```

Die erste Zeile der Ausgabe muss den eigenen Username zeigen (Beispiel Teilnehmer 5:
`clusterName: tln5`).

## Schritt 4: Helm-Repo hinzufuegen

```
helm repo add splunk-otel https://signalfx.github.io/splunk-otel-collector-chart
helm repo update
```

## Schritt 5: Forwarder installieren

```
kubectl create namespace splunk-forwarder
helm install splunk-log-forwarder \
  -f collector-values.yml \
  -f hec-token-values.yml \
  splunk-otel/splunk-otel-collector \
  -n splunk-forwarder
```

Der Cluster enthaelt damit **nur** den Forwarder - kein Splunk-Operator, keine
Splunk-Instanz. Der HEC-Endpoint in `collector-values.yml` zeigt auf die
externe VM aus Uebung 2.

Jedes Event traegt damit zwei Kennungen, ueber die sich in [Uebung 4](04-log-suche-crashloop-debugging.md)
die eigenen Daten von denen der anderen Teilnehmer trennen lassen: die Cluster-Kennung aus
Schritt 3 (Feld `k8s.cluster.name`, z.B. `tln5`) und automatisch den echten Node-Hostnamen
im `host`-Feld (die Nodes heissen `k8s-<username>-cp`, `k8s-<username>-w1`, ...,
z.B. `k8s-tln5-cp`).

## Schritt 6: Status pruefen

```
kubectl get pods -n splunk-forwarder
kubectl logs -n splunk-forwarder -l app=splunk-otel-collector --tail=20
```

Erwartete Ausgabe: DaemonSet-Pods `Running`, keine `Exporting failed`-Meldungen. Falls doch:

- Endpoint in `collector-values.yml` gegen
  `terraform -chdir=terraform-external-splunk output` pruefen
- HEC (Port 8088) verlangt HTTPS, auch wenn andere Ports auf der VM ggf. nur HTTP sprechen
- `401`/`403` deutet auf einen falschen Token hin (Schritt 2 wiederholen, Token beim
  Trainer gegenpruefen)

## Schritt 7: Aufraeumen der Secret-Datei (optional, aber empfohlen)

Sobald der Forwarder laeuft, kann die lokale Token-Datei geloescht werden - der Token steckt
danach nur noch im Kubernetes-Secret, das der Helm-Release selbst angelegt hat:

```
rm ~/helm-values/splunk-otel/hec-token-values.yml
```

Die `collector-values.yml` aus Schritt 3 enthaelt kein Secret und kann liegen bleiben.
Fuer eine spaetere Aenderung (`helm upgrade`) einfach Schritt 2 wiederholen.

Weiter mit [Uebung 4: Log-Suche und CrashLoopBackOff-Debugging](04-log-suche-crashloop-debugging.md),
um den Forwarder mit echten Daten zu fuellen und in der Splunk-Web-UI zu suchen.
