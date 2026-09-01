# HelmRelease - Helm Charts deklarativ mit Flux ausrollen

## Hintergrund

`HelmRelease` ist die zentrale Flux-CRD zum Ausrollen von Helm Charts. Der
helm-controller reconciled diese Ressource und fuehrt intern
`helm upgrade --install` aus.

| Eigenschaft | Beschreibung |
|-------------|--------------|
| API Group | `helm.toolkit.fluxcd.io/v2` |
| Controller | helm-controller |
| Funktion | Helm Release deklarativ verwalten |
| Reconciliation | Automatische Upgrades bei Aenderungen |

## Voraussetzungen

- `HelmRepository` `traefik` existiert (siehe [03-helmrepository.md](03-helmrepository.md))

## Schritt 1: Namespace anlegen

Der Namespace fuer das `HelmRelease`-Objekt muss existieren, bevor Flux das
Objekt darin anlegen kann - das ist reines Kubernetes-Verhalten und gilt
unabhaengig von GitOps:

```
kubectl create namespace ingress
```

## Schritt 2: HelmRelease fuer Traefik erstellen

```
cd
cd flux-<dein-kuerzel>/clusters/production/infrastructure
```

```
# vi 02-traefik-release.yml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: traefik
  namespace: ingress
spec:
  interval: 5m
  chart:
    spec:
      chart: traefik
      sourceRef:
        kind: HelmRepository
        name: traefik
        namespace: flux-system
  values:
    replicas: 2
```

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added HelmRelease traefik"
git push
```

## Schritt 3: Status pruefen

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl get helmrelease -n ingress
```

**Erwarteter Fehler:**

```
NAME      AGE   READY   STATUS
traefik   30s   False   Helm install failed for release ingress/traefik with chart traefik@41.4.0: ...
```

```
kubectl -n ingress describe helmrelease traefik
```

```
Warning  InstallFailed  ...  helm-controller  Helm install failed for release ingress/traefik with chart traefik@41.4.0: values don't meet the specifications of the schema(s) in the following chart(s):
traefik:
- at '': additional properties 'replicas' not allowed
```

Das Traefik-Chart erwartet `deployment.replicas`, nicht `replicas` auf
oberster Ebene. Um das richtige Feld zu finden, hilft ein Blick auf
[artifacthub.io](https://artifacthub.io/packages/helm/traefik/traefik)
(Values-Schema des Charts).

## Schritt 4: Values korrigieren

```
# vi 02-traefik-release.yml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: traefik
  namespace: ingress
spec:
  interval: 5m
  chart:
    spec:
      chart: traefik
      sourceRef:
        kind: HelmRepository
        name: traefik
        namespace: flux-system
  values:
    deployment:
      replicas: 2
```

```
git add -A
git commit -m "Fixed values schema for traefik"
git push
```

## Schritt 5: Erfolg pruefen

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl get helmrelease -n ingress
kubectl -n ingress get pods
helm -n ingress list
```

Erwartete Ausgabe:

```
NAME      AGE   READY   STATUS
traefik   63s   True    Helm install succeeded for release ingress/traefik.v1 with chart traefik@41.4.0

NAME                       READY   STATUS    RESTARTS   AGE
traefik-...                1/1     Running   0          27s
traefik-...                1/1     Running   0          27s
```

**Erklaerung:**

| Feld | Wert | Bedeutung |
|------|------|-----------|
| `interval` | `5m` | Pruefe alle 5 Minuten auf Drift/Updates |
| `chart` | `traefik` | Chart-Name aus dem Repository |
| `sourceRef` | `traefik` | Referenz auf das `HelmRepository` |
| `values` | ... | Ueberschreibt die Chart-Default-Values |

## Details des HelmRelease anzeigen

```
kubectl get helmrelease traefik -n ingress -o yaml | grep -A 10 status
```

Wichtige Felder: `lastAttemptedRevision` (letzte versuchte Version),
`conditions` (Status der Reconciliation).

## Naechster Schritt

Im naechsten Schritt ([05-oci-helm-chart.md](05-oci-helm-chart.md)) rollt
ihr ein Helm Chart aus einer OCI-Registry aus.

## Aufraeumen

```
rm clusters/production/infrastructure/02-traefik-release.yml
git add -A
git commit -m "Removed HelmRelease traefik"
git push
kubectl delete namespace ingress
```
