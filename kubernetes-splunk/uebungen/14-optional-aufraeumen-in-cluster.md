# Uebung 14 (optional): Aufraeumen (In-Cluster-Variante)

> **Optionaler Anhang** - raeumt auf, was in den Uebungen 10-13 angelegt wurde.

## Schritt 1: Log-Forwarder, Splunk und Operator entfernen

```
helm uninstall splunk-log-forwarder -n splunk-operator
helm uninstall splunk-enterprise-test -n splunk-operator
helm uninstall splunk-operator-test -n splunk-operator
kubectl delete namespace splunk-operator
```

## Schritt 2: Persistent Volumes pruefen

Der Chart bereinigt PersistentVolumeClaims nicht automatisch.

```
kubectl get pvc -A
kubectl get pv
```

Verwaiste PVCs/PVs bei Bedarf loeschen:

```
kubectl delete pvc <name> -n splunk-operator
```

## Schritt 3: CRDs entfernen (optional)

Nur noetig, wenn der Operator komplett vom Cluster entfernt werden soll.

```
kubectl delete -f https://github.com/splunk/splunk-operator/releases/download/3.1.0/splunk-operator-crds.yaml
```

Der Abbau des geteilten DOKS-Clusters/Bastion selbst steht in
[Uebung 5, Schritt 3](05-aufraeumen.md).
