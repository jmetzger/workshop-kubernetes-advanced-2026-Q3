# Uebung 13 (optional): Log-Forwarder installieren (In-Cluster-Variante)

> **Optionaler Anhang** - Fortsetzung von [Uebung 12](12-optional-splunk-ui-zugriff-in-cluster.md).
> Gleicher Forwarder wie in [Uebung 3](03-forwarder-an-externe-splunk.md), diesmal aber mit
> Ziel-Endpoint der In-Cluster-Splunk-Instanz statt der externen VM.

## Hintergrund

**Hinweis:** Das aeltere "Splunk Connect for Kubernetes" (fluentd-basiert) ist mittlerweile
archiviert - sein Docker-Image `splunk/fluentd-hec` wurde von Docker Hub entfernt und
`helm install` endet in `ImagePullBackOff`. Diese Uebung nutzt stattdessen den aktuell von
Splunk gepflegten Nachfolger, den **Splunk OpenTelemetry Collector**, der ebenfalls direkt
per HEC an Splunk Enterprise senden kann (nicht nur an Splunk Observability Cloud).

## Schritt 1: HEC-Token auslesen

Der Splunk Operator hat beim ersten Start automatisch einen HEC-Token generiert.

```
kubectl get secret splunk-stdln-standalone-secret-v1 -n splunk-operator -o jsonpath='{.data.hec_token}' | base64 -d
echo
```

## Schritt 2: Token in eine eigene Secret-Values-Datei eintragen

Den Token **nicht** per `--set` auf der Kommandozeile uebergeben (landet sonst in der
Bash-History und ggf. in `helm history`), sondern in eine eigene, kleine YAML-Datei
schreiben. Diese Datei bleibt nur lokal auf dem Bastion, wird nicht committed
(`.gitignore` deckt `hec-token-values.yml` ab) und ist die einzige Stelle, an der der Token
im Klartext steht:

```
nano /tmp/hec-token-values.yml
```

Inhalt:

```
splunkPlatform:
  token: <HEC-TOKEN aus Schritt 1>
```

Diese Datei wird ab jetzt bei **jedem** `helm install`/`helm upgrade` fuer den Forwarder als
zweite `-f`-Datei mitgegeben (siehe Schritt 4) - so bleibt der Token an einer einzigen Stelle
gepflegt, unabhaengig davon wie oft die Konfiguration sich sonst noch aendert.

## Schritt 3: Helm-Repo hinzufuegen

Eigener Repo-Name noetig, da `splunk` schon fuer den Operator-Chart-Repo belegt ist
(zeigt auf eine andere URL).

```
helm repo add splunk-otel https://signalfx.github.io/splunk-otel-collector-chart
helm repo update
```

## Schritt 4: Collector installieren

Zwei `-f`-Dateien: die allgemeine Konfiguration (`splunk-manifests/03-splunk-otel-collector-values.yml`,
im Repo, ohne Token) und die Secret-Values-Datei aus Schritt 2 (nur lokal, mit Token). Die
zweite Datei ueberschreibt/ergaenzt die erste.

```
helm install splunk-log-forwarder \
  -f splunk-manifests/03-splunk-otel-collector-values.yml \
  -f /tmp/hec-token-values.yml \
  splunk-otel/splunk-otel-collector \
  -n splunk-operator
```

Fuer spaetere Konfigurationsaenderungen (z.B. Endpoint korrigieren) denselben Befehl mit
`helm upgrade` statt `helm install` nutzen - die Secret-Values-Datei bleibt dabei immer die
zweite `-f`:

```
helm upgrade splunk-log-forwarder \
  -f splunk-manifests/03-splunk-otel-collector-values.yml \
  -f /tmp/hec-token-values.yml \
  splunk-otel/splunk-otel-collector \
  -n splunk-operator
```

## Schritt 5: Forwarder-Status pruefen

```
kubectl get pods -n splunk-operator -l app=splunk-otel-collector
kubectl logs -n splunk-operator -l app=splunk-otel-collector --tail=20
```

Erwartete Ausgabe: ein DaemonSet-Pod pro Node im Status `Running`, in den Logs keine
`Exporting failed`-Meldungen mehr. Falls doch: haeufigste Ursache ist ein falscher Token
(`401`/`403`) oder ein falsches Protokoll am Endpoint - HEC (Port 8088) verlangt HTTPS, auch
wenn die Splunk-Web-UI (Port 8000) in diesem Deployment nur HTTP spricht.

## Schritt 6: Aufraeumen der Secret-Datei (optional, aber empfohlen)

Sobald der Forwarder laeuft, kann die lokale Token-Datei geloescht werden - der Token steckt
danach nur noch im Kubernetes-Secret, das der Helm-Release selbst angelegt hat:

```
rm /tmp/hec-token-values.yml
```

Fuer eine spaetere Aenderung (`helm upgrade`) einfach Schritt 1+2 wiederholen.

Fuer die Suche nach CrashLoopBackOff-Events kann Uebung 4 sinngemaess wiederholt werden,
diesmal gegen die In-Cluster-Web-UI aus Uebung 12 statt der externen VM.

Zum Aufraeumen dieser Variante: [Uebung 14](14-optional-aufraeumen-in-cluster.md).
