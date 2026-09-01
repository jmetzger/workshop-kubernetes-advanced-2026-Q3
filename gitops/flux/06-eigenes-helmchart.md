# Eigenes Helm Chart aus einem Git-Repository ausrollen

## Hintergrund

`GitRepository` ist die Flux-CRD fuer Git als Quelle - damit koennt ihr auch
ein eigenes, selbst geschriebenes Helm Chart per Flux ausrollen, ohne es
vorher in eine Chart-Registry zu veroeffentlichen.

| Eigenschaft | Beschreibung |
|-------------|--------------|
| API Group | `source.toolkit.fluxcd.io/v1` |
| Controller | source-controller |
| Funktion | Git-Repository als Quelle bereitstellen |

## Voraussetzungen

- Flux gebootstrapped (siehe [02-installation.md](02-installation.md))

## Schritt 1: Chart erstellen

```
cd
mkdir helm-chart-test
cd helm-chart-test
helm create final-chart
```

## Schritt 2: Neues, leeres GitLab-Repo anlegen

Auf gitlab.com als `training.tn<deine-nr>`: neues Projekt
`final-chart-<dein-kuerzel>` anlegen, **Sichtbarkeit: Public** (der
source-controller braucht sonst Zugangsdaten fuer dieses zweite Repo, was
wir uns fuer die Uebung sparen).

## Schritt 3: Chart lokal committen und pushen

```
cd final-chart
git init
git config user.email "training@example.com"
git config user.name "training.tn<deine-nr>"
git remote add origin https://gitlab.com/training.tn<deine-nr>/final-chart-<dein-kuerzel>.git
git add -A
git commit -m "Chart hochschicken"
git branch -M main
git push -u origin main
```

Bei der ersten Push-Authentifizierung: Username `training.tn<deine-nr>`,
Passwort der Personal Access Token aus [02-installation.md](02-installation.md).

## Schritt 4: GitRepository im Flux-Repo anlegen

```
cd
cd flux-<dein-kuerzel>
mkdir -p clusters/production/apps
cd clusters/production/apps
```

```
# vi 01-final-chart-gitrepo.yml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: final-chart-source
  namespace: flux-system
spec:
  interval: 1m
  url: https://gitlab.com/training.tn<deine-nr>/final-chart-<dein-kuerzel>.git
  ref:
    branch: main
```

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added GitRepository for own chart"
git push
```

## Schritt 5: Ueberpruefen

```
flux reconcile kustomization flux-system --with-source
```

```
flux get sources git
```

Erwartete Ausgabe (Auszug):

```
NAME                 REVISION                                          READY
final-chart-source   main@sha1:...                                     True
```

## Schritt 6: HelmRelease einpflegen

```
cd flux-<dein-kuerzel>/clusters/production/apps
```

```
# vi 02-final-chart-release.yml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: final-chart
  namespace: flux-system
spec:
  interval: 1m
  targetNamespace: final-chart-demo
  install:
    createNamespace: true
  chart:
    spec:
      chart: ./
      sourceRef:
        kind: GitRepository
        name: final-chart-source
        namespace: flux-system
  values:
    replicaCount: 2
```

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added HelmRelease for own chart"
git push
```

**Erklaerung:** `chart.spec.chart: ./` verweist auf das Wurzelverzeichnis des
`GitRepository` - das Chart liegt hier direkt im Repo-Root. Liegt das Chart
in einem Unterordner (z.B. `charts/final-chart`), muss der Pfad entsprechend
angepasst werden.

## Schritt 7: Ueberpruefen

```
flux reconcile kustomization flux-system --with-source
```

```
flux get source git
flux get helmrelease -A
helm list -A
kubectl -n final-chart-demo get pods
```

Erwartete Ausgabe:

```
NAME          AGE   READY   STATUS
final-chart   ...   True    Helm install succeeded for release final-chart-demo/final-chart-demo-final-chart.v1 with chart final-chart@0.1.0

NAME                                           READY   STATUS    RESTARTS   AGE
final-chart-demo-final-chart-...               1/1     Running   0          28s
final-chart-demo-final-chart-...               1/1     Running   0          28s
```

## Zusammenfassung der gesamten Uebungsreihe

| CRD | Zweck |
|-----|-------|
| `HelmRepository` | HTTP-Chart-Repository als Quelle |
| `HelmRelease` (mit `chart.spec`) | Helm Release aus `HelmRepository` |
| `OCIRepository` | Helm Chart aus OCI-Registry als Quelle |
| `HelmRelease` (mit `chartRef`) | Helm Release aus `OCIRepository` |
| `GitRepository` | Eigenes/fremdes Git-Repo als Quelle |
| `HelmRelease` (mit `chart.spec` + `GitRepository`) | Helm Release aus einem Chart-Pfad im Git-Repo |

Der gesamte Workflow lief dabei ausschliesslich ueber `git commit` +
`git push` in euer Flux-Repo - kein einziges `kubectl apply` fuer die
eigentlichen GitOps-Objekte. Genau das ist der Kern von GitOps: Git ist die
"Source of Truth", Flux gleicht den Cluster automatisch daran an.

## Aufraeumen

```
cd flux-<dein-kuerzel>
rm clusters/production/apps/01-final-chart-gitrepo.yml
rm clusters/production/apps/02-final-chart-release.yml
git add -A
git commit -m "Removed own chart GitRepository and HelmRelease"
git push
```

Das GitLab-Repo `final-chart-<dein-kuerzel>` koennt ihr danach in den
Projekt-Einstellungen loeschen.
