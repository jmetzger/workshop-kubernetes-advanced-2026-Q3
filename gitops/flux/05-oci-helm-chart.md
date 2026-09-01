# OCI-Helm-Chart verwenden

## Hintergrund

Helm Charts koennen auch direkt aus einer OCI-Registry (z.B. Docker Hub,
GHCR) bezogen werden - ohne klassisches HTTP-Chart-Repository. Flux bildet
das mit der CRD `OCIRepository` ab.

| Eigenschaft | Beschreibung |
|-------------|--------------|
| API Group | `source.toolkit.fluxcd.io/v1` |
| Controller | source-controller |
| Funktion | OCI-Artifact (Helm Chart) als Quelle bereitstellen |

## Voraussetzungen

- Flux gebootstrapped (siehe [02-installation.md](02-installation.md))

## Schritt 1: OCIRepository einrichten

```
cd
cd flux-<dein-kuerzel>/clusters/production/infrastructure
```

```
# vi 03-mariadb-ocirepo.yml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: cloudpirates-mariadb
  namespace: flux-system
spec:
  interval: 10m
  url: oci://registry-1.docker.io/cloudpirates/mariadb
  ref:
    version: "0.14.1"
```

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added OCIRepository cloudpirates-mariadb"
git push
```

## Schritt 2: Funktioniert nicht - warum?

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl -n flux-system get ocirepositories
```

**Erwarteter Fehler:**

```
Error from server (BadRequest): OCIRepository in version "v1" cannot be handled as a OCIRepository: strict decoding error: unknown field "spec.ref.version"
```

Das Feld heisst nicht `version`, sondern `tag`. Nachschauen, welche Felder
unter `ref` erlaubt sind:

```
kubectl explain OCIRepository.spec.ref
```

Ausgabe zeigt u.a. `tag`, `semver`, `digest` - aber kein `version`.

## Schritt 3: Feld korrigieren

```
# vi 03-mariadb-ocirepo.yml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: cloudpirates-mariadb
  namespace: flux-system
spec:
  interval: 10m
  url: oci://registry-1.docker.io/cloudpirates/mariadb
  ref:
    tag: "0.14.1"
```

```
git add -A
git commit -m "Fixed OCIRepository ref field"
git push
```

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl -n flux-system get ocirepositories
```

Erwartete Ausgabe:

```
NAME                   URL                                               READY   STATUS
cloudpirates-mariadb   oci://registry-1.docker.io/cloudpirates/mariadb   True    stored artifact for digest '0.14.1@sha256:...'
```

## Schritt 4: HelmRelease anlegen

Bei einem `OCIRepository` wird `chartRef` statt `chart.spec` verwendet, weil
die Chart-Version bereits im `OCIRepository` festgelegt ist.

```
# vi 04-mariadb-release.yml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: mariadb
  namespace: default
spec:
  interval: 10m
  chartRef:
    kind: OCIRepository
    name: cloudpirates-mariadb
    namespace: flux-system
  values:
    persistence:
      enabled: false
```

**Hinweis:** `persistence.enabled: false` ist hier bewusst gesetzt - ohne
StorageClass im Cluster wuerde der Pod sonst mit einer unbound
PersistentVolumeClaim in `Pending` haengen bleiben. Fuer eine echte
Persistence-Uebung braeuchte es eine StorageClass (z.B. per NFS-CSI-Treiber)
- das ist fuer diese Uebung bewusst ausgeklammert.

```
git add -A
git commit -m "Added HelmRelease mariadb"
git push
```

## Schritt 5: War die Installation erfolgreich?

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl get helmrelease -n default
kubectl get pods -n default
helm -n default status mariadb
```

Erwartete Ausgabe:

```
NAME      AGE   READY   STATUS
mariadb   90s   True    Helm install succeeded for release default/mariadb.v1 with chart mariadb@0.14.1+...

NAME        READY   STATUS    RESTARTS   AGE
mariadb-0   1/1     Running   0          44s
```

## Naechster Schritt

Im naechsten Schritt ([06-eigenes-helmchart.md](06-eigenes-helmchart.md))
rollt ihr ein eigenes Helm Chart aus einem eigenen Git-Repository aus.

## Aufraeumen

```
rm clusters/production/infrastructure/03-mariadb-ocirepo.yml
rm clusters/production/infrastructure/04-mariadb-release.yml
git add -A
git commit -m "Removed mariadb OCIRepository and HelmRelease"
git push
```
