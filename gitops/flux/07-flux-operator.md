# Flux Operator - deklarative Installation statt `flux bootstrap`

## Hintergrund

In [02-installation.md](02-installation.md) habt ihr Flux imperativ per CLI
installiert: `flux bootstrap` generiert die Controller-Manifeste, committed
sie ins Git-Repo und wartet, bis alles laeuft - ein einmaliger, imperativer
Befehl.

Der **Flux Operator** (von ControlPlane, https://fluxoperator.dev) macht aus
"Flux installieren" selbst eine GitOps-Ressource: Ihr installiert einen
kleinen Operator per Helm, und der Operator liest daraus eine `FluxInstance`
Custom Resource, welche Flux-Version, welche Controller und welche
Cluster-Einstellungen gewuenscht sind. Der Operator rollt Flux dann aus -
und haelt es aktuell, sobald ihr die `FluxInstance` aendert (z.B. Upgrade auf
eine neue Flux-Version per `kubectl apply` statt per CLI-Rerun).

| Ansatz | Werkzeug | Wie wird installiert? | Wie wird geupgraded? |
|--------|----------|------------------------|------------------------|
| `flux bootstrap` | Flux CLI | Einmaliger CLI-Befehl | `flux bootstrap` erneut ausfuehren |
| Flux Operator | Helm + CRD | Deklarative `FluxInstance`-Ressource | `FluxInstance` bearbeiten (`kubectl apply`/GitOps) |

**Wichtig:** Diese Uebung installiert nur Flux selbst deklarativ - anders als
`flux bootstrap` richtet sie **keinen** Git-Sync (`GitRepository` +
`Kustomization`) ein. Fuer die nachfolgenden Uebungen 03-06 (die auf dem per
`flux bootstrap` eingerichteten Git-Sync aufbauen) bleibt weiterhin
02-installation.md der Weg. Diese Uebung steht als Alternative daneben, um
den deklarativen Ansatz zu vergleichen.

| Komponente | Version (Stand 09.09.2026) |
|------------|------------------------------|
| Flux Operator (Helm Chart) | 0.59.0 |
| Flux Distribution (ueber FluxInstance) | 2.9.5 |

## Voraussetzungen

- Eigenes Kubernetes-Cluster (jeder Teilnehmer hat sein eigenes)
- kubectl konfiguriert
- helm installiert

## Schritt 1: Flux Operator per Helm installieren

Der Operator kommt als Helm Chart aus einer OCI-Registry - kein zusaetzliches
Repo hinzufuegen noetig:

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

## Schritt 2: FluxInstance anlegen

Die `FluxInstance` beschreibt, welche Flux-Version und welche Controller
ausgerollt werden sollen:

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
```

```
kubectl apply -f fluxinstance.yml
```

## Schritt 3: Rollout pruefen

```
kubectl get pods -n flux-system
```

Erwartete Ausgabe (Operator + 4 Flux-Controller):

```
NAME                                       READY   STATUS    RESTARTS   AGE
flux-operator-xxxxxxxxxx-xxxxx              1/1     Running   0          2m
helm-controller-xxxxxxxxxx-xxxxx           1/1     Running   0          30s
kustomize-controller-xxxxxxxxxx-xxxxx      1/1     Running   0          30s
notification-controller-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
source-controller-xxxxxxxxxx-xxxxx         1/1     Running   0          30s
```

Status der `FluxInstance` selbst:

```
kubectl get fluxinstance -n flux-system
```

Erwartete Ausgabe:

```
NAME   AGE   READY   STATUS                           REVISION
flux   40s   True    Reconciliation finished in 21s   v2.9.5@sha256:...
```

`READY = True` heisst: Der Operator hat die gewuenschte Flux-Version
erfolgreich ausgerollt - ohne dass ihr die Flux CLI installieren oder
`flux bootstrap` ausfuehren musstet.

Der Operator schreibt zusaetzlich einen `FluxReport` mit Details zur
laufenden Installation:

```
kubectl get fluxreport -n flux-system
```

## Was passiert im Hintergrund?

1. Der Flux Operator (aus Schritt 1) beobachtet `FluxInstance`-Ressourcen
2. Er laedt die passenden Flux-Controller-Manifeste fuer die angeforderte
   Version/Registry
3. Er rollt `source-controller`, `kustomize-controller`, `helm-controller`
   und `notification-controller` im Cluster aus
4. Er ueberwacht den Zustand laufend und schreibt Status in
   `FluxInstance.status` und `FluxReport`
5. Aendert ihr die `FluxInstance` (z.B. andere `version`), rollt der Operator
   das Update automatisch aus - ganz ohne erneuten CLI-Aufruf

## Vergleich zu `flux bootstrap`

| | `flux bootstrap` | Flux Operator + `FluxInstance` |
|---|---|---|
| Installation | Imperativer CLI-Befehl | Deklarative Custom Resource |
| Git-Sync (GitRepository/Kustomization) | Wird automatisch mit eingerichtet | Optional, separat ueber `spec.sync` |
| Voraussetzung | Flux CLI + Git-Token | Nur Helm |
| Upgrade | CLI-Befehl erneut ausfuehren | `FluxInstance` bearbeiten |
| Selbst GitOps-faehig | Nein (Bootstrap ist einmalig) | Ja (Operator reconciled dauerhaft) |

## Aufraeumen

Erst die `FluxInstance` loeschen - der Operator entfernt dann die vier
Flux-Controller sauber (inkl. Finalizer-Handling), der Operator selbst
bleibt zunaechst stehen:

```
kubectl delete fluxinstance flux -n flux-system
```

```
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
