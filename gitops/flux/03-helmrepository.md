# HelmRepository - Helm Chart Repositories mit Flux verwalten

## Hintergrund

`HelmRepository` ist die Flux-CRD, die ein Helm-Chart-Repository als Quelle
definiert. Der source-controller ueberwacht diese Ressource und laedt
periodisch den Repository-Index (`index.yaml`).

| Eigenschaft | Beschreibung |
|-------------|--------------|
| API Group | `source.toolkit.fluxcd.io/v1` |
| Controller | source-controller |
| Funktion | Helm-Chart-Repository-Index bereitstellen |
| Update | Periodisch (`interval`) |

## Voraussetzungen

- Flux gebootstrapped (siehe [02-installation.md](02-installation.md))
- Euer Repo `flux-<dein-kuerzel>` lokal geklont

## Schritt 1: Vorbereitung

```
cd
cd flux-<dein-kuerzel>
mkdir -p clusters/production/infrastructure
cd clusters/production/infrastructure
```

## Schritt 2: HelmRepository fuer Traefik erstellen

```
# vi 01-traefik-repo.yml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 10m
  url: https://traefik.github.io/charts
```

Nicht `kubectl apply` - stattdessen committen und pushen:

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added HelmRepository traefik"
git push
```

## Schritt 3: Reconciliation abwarten

Flux zieht Aenderungen automatisch (Standard-Intervall der Kustomization).
Fuer die Uebung koennt ihr das manuell anstossen:

```
flux reconcile kustomization flux-system --with-source
```

```
kubectl get helmrepository -n flux-system
```

Erwartete Ausgabe:

```
NAME      URL                                AGE   READY   STATUS
traefik   https://traefik.github.io/charts   15s   True    stored artifact: revision 'sha256:...'
```

**Erklaerung:**

| Feld | Wert | Bedeutung |
|------|------|-----------|
| `interval` | `10m` | Alle 10 Minuten Index neu laden |
| `url` | `https://...` | Helm-Chart-Repository-URL |
| `READY` | `True` | Repository-Index erfolgreich geladen |

## Was passiert im Hintergrund?

1. `git push` bringt die Aenderung ins GitLab-Repo
2. Der source-controller im Cluster erkennt (per `GitRepository`
   `flux-system`) den neuen Commit
3. Der kustomize-controller wendet die neuen Manifeste aus
   `clusters/production/` an (das erstellt hier das `HelmRepository`-Objekt)
4. Der source-controller laedt daraufhin `index.yaml` vom Traefik-Repo

## Naechster Schritt

Im naechsten Schritt ([04-helmrelease.md](04-helmrelease.md)) nutzt ihr
dieses `HelmRepository`, um tatsaechlich ein Helm Chart mit `HelmRelease`
auszurollen.

## Aufraeumen

Nicht ausfuehren, falls ihr direkt mit der naechsten Uebung weitermacht -
die `HelmRelease` braucht das `HelmRepository` als Quelle.

```
rm clusters/production/infrastructure/01-traefik-repo.yml
git add -A
git commit -m "Removed HelmRepository traefik"
git push
```
