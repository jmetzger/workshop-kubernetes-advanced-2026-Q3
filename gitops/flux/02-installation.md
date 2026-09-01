# Flux Installation und GitOps-Bootstrap mit GitLab

## Hintergrund

Flux laeuft im Cluster als mehrere Controller. Anders als bei einem reinen
`helm install` verdrahten wir Flux hier gleich richtig als GitOps-Tool: Der
Bootstrap installiert die Controller UND richtet ein Git-Repository als
Quelle ein, aus dem Flux ab sofort alle weiteren Aenderungen zieht. Danach
gibt es (bis auf einmalige Namespace-Anlagen) kein `kubectl apply` mehr fuer
eure Manifeste - nur noch `git commit` + `git push`.

| Komponente | Version (Stand 31.08.2026) |
|------------|------------------------------|
| Flux CLI / App | 2.9.4 |

## Voraussetzungen

- Eigenes Kubernetes-Cluster (jeder Teilnehmer hat sein eigenes)
- kubectl konfiguriert
- Eigener GitLab.com-Account `training.tn<deine-nr>` (vom Trainer angelegt)

## Schritt 1: Flux CLI installieren

```
curl -s https://fluxcd.io/install.sh | sudo bash
```

```
flux version --client
```

```
flux check --pre
```

## Schritt 2: Personal Access Token erstellen

Auf gitlab.com unter `https://gitlab.com/-/user_settings/personal_access_tokens`
(als `training.tn<deine-nr>` eingeloggt):

- Scope: `api`
- Name z.B. `flux-bootstrap`

Token kopieren und als Umgebungsvariable setzen:

```
export GITLAB_TOKEN=<dein-personal-access-token>
```

## Schritt 3: GitLab-Repo einrichten

Neues, leeres Projekt anlegen: `https://gitlab.com/projects/new#blank_project`,
Name z.B. `flux-<dein-kuerzel>`.

## Schritt 4: Flux bootstrappen

```
flux bootstrap gitlab \
  --token-auth \
  --owner=training.tn<deine-nr> \
  --repository=flux-<dein-kuerzel> \
  --branch=main \
  --path=clusters/production
```

Das dauert ca. 1-2 Minuten. Flux macht dabei:

1. Generiert die Controller-Manifeste und committed sie ins Repo
2. Installiert die Controller im Cluster (Namespace `flux-system`)
3. Legt ein `GitRepository`- und `Kustomization`-Objekt an, das auf euer
   eigenes Repo zeigt
4. Wartet, bis alles reconciled und gesund ist

**Erwartetes Ende der Ausgabe:**

```
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```

## Schritt 5: Repo lokal klonen

Ab jetzt bearbeitet ihr Manifeste in eurem eigenen Repo:

```
cd
git clone https://gitlab.com/training.tn<deine-nr>/flux-<dein-kuerzel>.git
cd flux-<dein-kuerzel>
```

```
git config user.email "training@example.com"
git config user.name "training.tn<deine-nr>"
```

## Schritt 6: Installation verifizieren

```
kubectl get pods -n flux-system
```

Erwartete Ausgabe (6 Controller):

```
NAME                                           READY   STATUS    RESTARTS   AGE
helm-controller-...                            1/1     Running   0          33s
image-automation-controller-...                1/1     Running   0          33s
image-reflector-controller-...                 1/1     Running   0          33s
kustomize-controller-...                       1/1     Running   0          33s
notification-controller-...                    1/1     Running   0          33s
source-controller-...                          1/1     Running   0          33s
```

```
flux get sources git
flux get kustomizations
```

## Was wurde installiert?

1. 6 Controller-Pods im Namespace `flux-system`
2. Ein `GitRepository`-Objekt `flux-system`, das auf euer eigenes GitLab-Repo
   zeigt
3. Eine `Kustomization`, die alles unter `clusters/production/` aus diesem
   Repo automatisch anwendet

Im naechsten Schritt legt ihr ein `HelmRepository` an - nicht per
`kubectl apply`, sondern per Commit in dieses Repo.

## Aufraeumen

Nur ausfuehren, wenn ihr die komplette Uebungsreihe abschliesst - die
folgenden Uebungen brauchen den Bootstrap weiterhin.

**Wichtig:** Zuerst alle selbst angelegten `HelmRelease`/`HelmRepository`/
`OCIRepository`/`GitRepository`-Objekte aus den Uebungen entfernen (siehe
jeweiliger Aufraeumen-Abschnitt) - danach erst deinstallieren:

```
flux uninstall --namespace=flux-system
```

`flux uninstall` entfernt Custom Resources, Controller, Namespace und CRDs
in der richtigen Reihenfolge. **Nicht** einfach `kubectl delete namespace
flux-system` gefolgt von `kubectl delete crds ...` verwenden: Wenn dabei die
Controller-Pods verschwinden, bevor sie die Finalizer auf uebrig gebliebenen
Custom Resources entfernt haben, bleibt der Namespace fuer immer in
`Terminating` haengen (nur noch von Hand ueber
`kubectl patch <resource> -p '{"metadata":{"finalizers":[]}}' --type=merge`
loesbar).

Das GitLab-Repo `flux-<dein-kuerzel>` koennt ihr danach in den
Projekt-Einstellungen loeschen.
