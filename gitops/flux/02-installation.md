# Flux Installation und GitOps-Sync mit dem Flux Operator

## Hintergrund

Frueher haette man Flux imperativ per `flux bootstrap gitlab ...` installiert:
Ein einmaliger CLI-Befehl generiert die Controller-Manifeste, committed sie
ins Git-Repo, installiert die Controller und richtet ein `GitRepository` +
eine `Kustomization` als Git-Sync ein. Inzwischen wird stattdessen der Flux
Operator **empfohlen** (siehe auch [ArgoCD vs. Flux CD](../argocd-vs-flux.md)):

In dieser Uebung macht das stattdessen der **Flux Operator** (von
ControlPlane, https://fluxoperator.dev): Ihr installiert per Helm nur einen
kleinen Operator. Der Operator liest daraus eine `FluxInstance` Custom
Resource - deklarativ, per `kubectl apply`/Git statt per CLI-Befehl - und
rollt darauf basierend die eigentlichen Flux-Controller samt Git-Sync aus.

Das bringt zwei Automatik-Effekte, die `flux bootstrap` nicht hat:

1. **Flux selbst aktualisiert sich automatisch:** `spec.distribution.version:
   "2.x"` in der `FluxInstance` heisst "immer die neueste 2.x-Version" - der
   Operator rollt neue Flux-Patches/Minor-Releases selbststaendig aus, ohne
   dass ihr `flux bootstrap` erneut ausfuehren muesst.
2. **Der Operator aktualisiert sich selbst:** Sobald der Git-Sync steht,
   committen wir eine `HelmRelease`, die den Flux-Operator-Chart selbst per
   Semver-Range trackt. Ab dann uebernimmt Flux die eigene Operator-Version -
   ein neuer Chart-Release wird automatisch ausgerollt, ganz ohne erneuten
   `helm upgrade`.

| Komponente | Version |
|------------|---------|
| Flux CLI | 2.9.5 (Stand 10.09.2026) |
| Flux Operator (Helm Chart) | 0.59.0 (Stand 09.09.2026) |
| Flux Distribution (ueber FluxInstance) | 2.9.5 (Stand 09.09.2026) |

## Voraussetzungen

- Eigenes Kubernetes-Cluster (jeder Teilnehmer hat sein eigenes)
- kubectl und helm konfiguriert
- Eigener GitLab.com-Account `training.tn<deine-nr>` (vom Trainer angelegt)

## Schritt 1: Flux CLI installieren

Wird hier nicht fuer die Installation gebraucht, aber fuer Reconcile-/Status-
Befehle in den naechsten Uebungen:

```
curl -s https://fluxcd.io/install.sh | sudo bash
```

```
flux version --client
```

## Schritt 2: Personal Access Token erstellen

Auf gitlab.com unter `https://gitlab.com/-/user_settings/personal_access_tokens`
(als `training.tn<deine-nr>` eingeloggt):

- Scope: `api`
- Name z.B. `flux-sync`

Token kopieren und als Umgebungsvariable setzen:

```
export GITLAB_TOKEN=<dein-personal-access-token>
```

## Schritt 3: GitLab-Repo einrichten und lokal klonen

Neues, leeres Projekt anlegen: `https://gitlab.com/projects/new#blank_project`,
Name z.B. `flux-<dein-kuerzel>`.

```
cd
git clone https://gitlab.com/training.tn<deine-nr>/flux-<dein-kuerzel>.git
cd flux-<dein-kuerzel>
```

```
git config user.email "training@example.com"
git config user.name "training.tn<deine-nr>"
```

**Unterschied zu `flux bootstrap`:** Dort generiert der CLI-Befehl die
Manifeste automatisch und committed sie ins Repo. Hier legt ihr die
Manifeste selbst an und committet sie - genau der Workflow, den ihr auch in
den naechsten Uebungen (`HelmRepository`, `HelmRelease`, ...) verwendet.

## Schritt 4: Flux Operator per Helm installieren

Der Operator kommt als Helm Chart aus einer OCI-Registry - kein
zusaetzliches Repo hinzufuegen noetig:

```
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  -n flux-system --create-namespace --wait --timeout 3m
```

```
kubectl get pods -n flux-system
```

Erwartete Ausgabe (nur der Operator, noch keine Flux-Controller):

```
NAME                            READY   STATUS    RESTARTS   AGE
flux-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          20s
```

## Schritt 5: Pull-Secret fuer den Git-Sync anlegen

Damit der Operator euer GitLab-Repo lesen kann, braucht er ein Secret mit
Benutzername + Token:

```
kubectl create secret generic flux-system \
  --namespace=flux-system \
  --from-literal=username=training.tn<deine-nr> \
  --from-literal=password=$GITLAB_TOKEN
```

## Schritt 6: FluxInstance mit Git-Sync anlegen

Die `FluxInstance` beschreibt, welche Flux-Version, welche Controller UND
welches Git-Repo als Sync-Quelle gewuenscht sind:

```
cd
mkdir -p flux-<dein-kuerzel>/clusters/production/flux-system
cd flux-<dein-kuerzel>/clusters/production/flux-system
```

```
# vi fluxinstance.yml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.x"
    registry: "ghcr.io/fluxcd"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes
    multitenant: false
    networkPolicy: true
    domain: "cluster.local"
  sync:
    kind: GitRepository
    url: "https://gitlab.com/training.tn<deine-nr>/flux-<dein-kuerzel>.git"
    ref: "refs/heads/main"
    path: "clusters/production"
    pullSecret: "flux-system"
```

Diese allererste Anwendung muss per `kubectl apply` passieren - es laeuft ja
noch kein Flux, das einen Git-Commit einlesen koennte:

```
kubectl apply -f fluxinstance.yml
```

Danach committen wir dieselbe Datei in den Pfad, den die `FluxInstance`
gerade als Sync-Quelle eingerichtet hat - ab jetzt verwaltet Flux sich damit
selbst weiter, jede kuenftige Aenderung an der `FluxInstance` laeuft ueber
`git commit` + `git push`:

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added FluxInstance with git sync"
git push
```

## Schritt 7: Operator-Selbst-Update einrichten

Jetzt richten wir den zweiten Automatik-Effekt ein: Der Flux-Operator-Chart
selbst wird ab sofort per `HelmRelease` von Flux verwaltet, mit einer
Semver-Range, die neue Chart-Releases automatisch uebernimmt.

```
cd flux-<dein-kuerzel>/clusters/production/flux-system
```

```
# vi flux-operator-source.yml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: flux-operator
  namespace: flux-system
spec:
  interval: 30m
  url: oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator
  ref:
    semver: ">=0.59.0"
```

```
# vi flux-operator-release.yml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: flux-operator
  namespace: flux-system
spec:
  interval: 30m
  releaseName: flux-operator
  chartRef:
    kind: OCIRepository
    name: flux-operator
    namespace: flux-system
```

**Wichtig:** Der Release-Name (`releaseName: flux-operator`) ist bewusst
identisch mit der Helm-Installation aus Schritt 4. Flux erkennt die
bestehende Helm-Release-Storage und uebernimmt sie nahtlos - ohne
Neuinstallation.

```
cd
cd flux-<dein-kuerzel>
git add -A
git commit -m "Added self-update HelmRelease for flux-operator"
git push
```

```
flux reconcile kustomization flux-system --with-source
```

## Schritt 8: Installation verifizieren

```
kubectl get pods -n flux-system
```

Erwartete Ausgabe (Operator + 4 Flux-Controller):

```
NAME                                       READY   STATUS    RESTARTS   AGE
flux-operator-xxxxxxxxxx-xxxxx              1/1     Running   0          3m
helm-controller-xxxxxxxxxx-xxxxx           1/1     Running   0          90s
kustomize-controller-xxxxxxxxxx-xxxxx      1/1     Running   0          90s
notification-controller-xxxxxxxxxx-xxxxx   1/1     Running   0          90s
source-controller-xxxxxxxxxx-xxxxx         1/1     Running   0          90s
```

Status der `FluxInstance` und des Git-Syncs:

```
kubectl get fluxinstance -n flux-system
flux get sources git
flux get kustomizations
```

Erwartete Ausgabe der `FluxInstance`:

```
NAME   AGE   READY   STATUS                           REVISION
flux   3m    True    Reconciliation finished in 21s   v2.9.5@sha256:...
```

Status des Operator-Selbst-Updates:

```
kubectl get ocirepository,helmrelease -n flux-system flux-operator
```

## Was wurde eingerichtet?

1. Der Flux Operator (Schritt 4) plus die 4 Flux-Controller, die er anhand
   der `FluxInstance` ausgerollt hat
2. Ein `GitRepository`- und `Kustomization`-Objekt `flux-system`, das auf
   euer eigenes GitLab-Repo zeigt (von der `FluxInstance` per `spec.sync`
   erzeugt - dieselben Namen wie bei `flux bootstrap`)
3. Eine `OCIRepository` + `HelmRelease`, die den Flux-Operator-Chart selbst
   per Semver-Range trackt und bei neuen Releases automatisch upgraded

Im naechsten Schritt legt ihr ein `HelmRepository` an - nicht per
`kubectl apply`, sondern per Commit in dieses Repo (genau wie in Schritt 6/7
gerade schon gemacht).

## Vergleich zu `flux bootstrap`

| | `flux bootstrap` | Flux Operator + `FluxInstance` |
|---|---|---|
| Installation | Imperativer CLI-Befehl | Deklarative Custom Resource |
| Manifeste ins Repo committen | Automatisch durch den CLI-Befehl | Selbst angelegt und committed |
| Flux-Version aktuell halten | `flux bootstrap` erneut ausfuehren | Automatisch (`version: "2.x"`) |
| Operator/Werkzeug selbst aktuell halten | Entfaellt (kein separater Operator) | Automatisch (eigene `HelmRelease`) |
| Voraussetzung | Flux CLI + Git-Token | Helm + Git-Token |

## Aufraeumen

Nur ausfuehren, wenn ihr die komplette Uebungsreihe abschliesst - die
folgenden Uebungen brauchen den Git-Sync weiterhin.

**Wichtig:** Zuerst alle selbst angelegten `HelmRelease`/`HelmRepository`/
`OCIRepository`/`GitRepository`-Objekte aus den Uebungen entfernen (siehe
jeweiliger Aufraeumen-Abschnitt) - danach erst die `FluxInstance` loeschen.
Der Operator entfernt dann die vier Flux-Controller sauber (inkl.
Finalizer-Handling), der Operator selbst bleibt zunaechst stehen:

```
kubectl delete fluxinstance flux -n flux-system
kubectl get pods -n flux-system
```

Danach den Operator per Helm deinstallieren:

```
helm uninstall flux-operator -n flux-system
```

**Hinweis:** Helm entfernt die CRDs standardmaessig nicht (Resource-Policy
`keep`). Fuer eine vollstaendige Bereinigung:

```
kubectl delete crd fluxinstances.fluxcd.controlplane.io \
  fluxreports.fluxcd.controlplane.io \
  resourcesetinputproviders.fluxcd.controlplane.io \
  resourcesets.fluxcd.controlplane.io
```

```
kubectl delete namespace flux-system
```

Das GitLab-Repo `flux-<dein-kuerzel>` koennt ihr danach in den
Projekt-Einstellungen loeschen.
