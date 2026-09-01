# Uebung 10 (optional): Splunk Operator installieren

> **Optionaler Anhang.** Diese Uebung und die folgenden (10-14) betreiben Splunk selbst
> **im Cluster**, als Alternative zur externen VM aus Uebung 2. Fuer den Praxisbetrieb ist
> das der seltenere Weg (siehe [splunk-im-cluster-optional.md](../splunk-im-cluster-optional.md)) - hier aber lehrreich, weil
> sichtbar wird, was der Splunk Operator im Hintergrund automatisiert.

## Hintergrund

Splunk wird nicht direkt als Deployment betrieben, sondern ueber den offiziellen
[Splunk Operator](https://splunk.github.io/splunk-operator/) verwaltet. Der Operator bringt
eigene Custom Resources mit (z.B. `Standalone`, `IndexerCluster`, `SearchHeadCluster`) und
kuemmert sich um Lifecycle, Storage und Konfiguration von Splunk Enterprise im Cluster.

## Schritt 1: Custom Resource Definitions installieren

Die CRDs sind groesser als 1 MB, deshalb liefert Helm sie nicht mit aus. Sie muessen separat
per `kubectl apply --server-side` installiert werden.

```
kubectl apply --server-side -f https://github.com/splunk/splunk-operator/releases/download/3.1.0/splunk-operator-crds.yaml
kubectl get crd | grep splunk
```

Erwartete Ausgabe: mehrere CRDs mit `splunk.com` im Namen (z.B. `standalones.enterprise.splunk.com`).

## Schritt 2: Helm-Repo hinzufuegen

```
helm repo add splunk https://splunk.github.io/splunk-operator/
helm repo update
```

## Schritt 3: Namespace anlegen und Operator installieren

Der Operator akzeptiert beim Start die Splunk General Terms (SGT) - ohne das bleibt spaeter
jede Splunk-Instanz im Status `Error: license not accepted` haengen.

```
kubectl create namespace splunk-operator
helm install splunk-operator-test splunk/splunk-operator -n splunk-operator \
  --set splunkOperator.splunkGeneralTerms="--accept-sgt-current-at-splunk-com"
```

## Schritt 4: Operator-Status pruefen

```
kubectl get pods -n splunk-operator
kubectl logs -n splunk-operator -l app.kubernetes.io/name=splunk-operator --tail=30
```

Erwartete Ausgabe: ein Pod `splunk-operator-controller-manager-...` im Status `Running`, `1/1`.

Weiter mit [Uebung 11: Splunk Standalone deployen](11-optional-standalone-splunk-deployen.md).
