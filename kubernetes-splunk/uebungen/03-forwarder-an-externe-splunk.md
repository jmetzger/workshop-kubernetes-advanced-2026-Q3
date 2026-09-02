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

## Schritt 1: Token in eine Secret-Values-Datei eintragen

Den Token **nicht** per `--set` auf der Kommandozeile uebergeben (landet sonst in der
Bash-History und ggf. in `helm history`), sondern in eine eigene, kleine YAML-Datei
schreiben. Diese Datei bleibt nur lokal auf dem Bastion, wird nicht committed und ist die
einzige Stelle, an der der Token im Klartext steht:

```
nano /tmp/hec-token-values.yml
```

Inhalt:

```
splunkPlatform:
  token: <HEC-Token - gibt der Trainer bekannt; bei selbst aufgesetzter VM: TF_VAR_splunk_hec_token aus Uebung 2 Schritt 1>
```

## Schritt 2: Cluster-Kennung in eine Values-Datei eintragen

Alle Teilnehmer senden an dieselbe externe Splunk-Instanz in denselben Index. Damit sich
die eigenen Daten spaeter wieder herausfiltern lassen, bekommt jeder Forwarder eine
eindeutige Cluster-Kennung (`clusterName`), die als Feld `k8s.cluster.name` an jedes Event
angehaengt wird. Als Kennung dient der eigene Bastion-Username - der folgende Befehl setzt
ihn automatisch ein (`$(whoami)` wird von der Shell ersetzt):

```
cat > /tmp/cluster-values.yml << EOF
clusterName: $(whoami)
EOF
cat /tmp/cluster-values.yml
```

Erwartete Ausgabe (Beispiel Teilnehmer 5):

```
clusterName: tln5
```

## Schritt 3: Helm-Repo hinzufuegen

```
helm repo add splunk-otel https://signalfx.github.io/splunk-otel-collector-chart
helm repo update
```

## Schritt 4: Forwarder installieren

```
kubectl create namespace splunk-forwarder
helm install splunk-log-forwarder \
  -f splunk-manifests/04-splunk-otel-collector-external-values.yml \
  -f /tmp/hec-token-values.yml \
  -f /tmp/cluster-values.yml \
  splunk-otel/splunk-otel-collector \
  -n splunk-forwarder
```

Der Cluster enthaelt damit **nur** den Forwarder - kein Splunk-Operator, keine
Splunk-Instanz. Der HEC-Endpoint in
`splunk-manifests/04-splunk-otel-collector-external-values.yml` zeigt auf die IP/den
Hostnamen der externen VM aus Uebung 2.

Jedes Event traegt damit zwei Kennungen, ueber die sich in [Uebung 4](04-log-suche-crashloop-debugging.md)
die eigenen Daten von denen der anderen Teilnehmer trennen lassen: die Cluster-Kennung aus
Schritt 2 (Feld `k8s.cluster.name`, z.B. `tln5`) und automatisch den echten Node-Hostnamen
im `host`-Feld (die Nodes heissen `k8s-<username>-cp`, `k8s-<username>-w1`, ...,
z.B. `k8s-tln5-cp`).

## Schritt 5: Status pruefen

```
kubectl get pods -n splunk-forwarder
kubectl logs -n splunk-forwarder -l app=splunk-otel-collector --tail=20
```

Erwartete Ausgabe: DaemonSet-Pods `Running`, keine `Exporting failed`-Meldungen. Falls doch:

- Endpoint in `splunk-manifests/04-splunk-otel-collector-external-values.yml` gegen
  `terraform -chdir=terraform-external-splunk output` pruefen
- HEC (Port 8088) verlangt HTTPS, auch wenn andere Ports auf der VM ggf. nur HTTP sprechen
- `401`/`403` deutet auf einen falschen Token hin (Schritt 1 wiederholen, Token beim
  Trainer gegenpruefen)

## Schritt 6: Aufraeumen der Secret-Datei (optional, aber empfohlen)

Sobald der Forwarder laeuft, kann die lokale Token-Datei geloescht werden - der Token steckt
danach nur noch im Kubernetes-Secret, das der Helm-Release selbst angelegt hat:

```
rm /tmp/hec-token-values.yml
```

Die `/tmp/cluster-values.yml` aus Schritt 2 enthaelt kein Secret und kann liegen bleiben.
Fuer eine spaetere Aenderung (`helm upgrade`) einfach Schritt 1 wiederholen.

Weiter mit [Uebung 4: Log-Suche und CrashLoopBackOff-Debugging](04-log-suche-crashloop-debugging.md),
um den Forwarder mit echten Daten zu fuellen und in der Splunk-Web-UI zu suchen.
