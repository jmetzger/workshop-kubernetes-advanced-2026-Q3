# Flux Ueberblick - Controller, CRDs und Ablauf

## Hintergrund

Flux ist neben ArgoCD das zweite grosse GitOps-Tool fuer Kubernetes (Vergleich
siehe [argocd-vs-flux.md](../argocd-vs-flux.md)). Flux arbeitet "pull-based":

1. Quelle beobachten (Git/OCI/Helm-Repo/S3-Bucket)
2. Artefakt bauen (z.B. tar.gz mit Repo-Snapshot oder Helm-Chart-Artifact)
3. Zielzustand ableiten (Kustomize oder Helm)
4. Ist-Zustand im Cluster angleichen (apply/upgrade)
5. Wiederholen (in Intervallen), inkl. Status/Events

Flux "macht nichts einmalig", sondern reconciled immer wieder, bis Ist = Soll.

## Die Flux-Controller und ihre Aufgaben

Flux besteht aus mehreren Controllern (Deployments), die jeweils bestimmte
CRDs beobachten und reconciled ausfuehren:

### source-controller (Quellen + Artefakte)

- Holt Inhalte aus Git, OCI, HelmRepositories oder Buckets
- Erzeugt versionierte Artefakte und stellt sie fuer andere Controller bereit
- CRDs: `GitRepository`, `OCIRepository`, `HelmRepository`, `Bucket`, `HelmChart`

### helm-controller (Helm Releases)

- Installiert/Upgraded/Uninstallt Helm Releases anhand von `HelmRelease`
- Nutzt Chart-Artefakte aus dem source-controller als Input
- CRD: `HelmRelease`

### kustomize-controller (YAML / Kustomize)

- Rendert und applied Kubernetes-Ressourcen aus einem Source-Artefakt
- Unterstuetzt Kustomize (Overlays, Patches, Images)
- CRD: `Kustomization`

### notification-controller (Events/Alerts/Webhooks)

- Sendet Benachrichtigungen ueber Zustandsaenderungen (Slack/Webhook/Teams)
- Kann Webhooks empfangen (GitHub/GitLab) und dadurch sofort reconcilen
- CRDs: `Provider`, `Alert`, `Receiver`

### image-reflector-controller und image-automation-controller

- Scannen Container-Registries nach neuen Image-Tags (`ImageRepository`,
  `ImagePolicy`) und schreiben Updates automatisiert zurueck ins Git-Repo
  (`ImageUpdateAutomation`)
- Sind Teil des Standard-Helm-Charts, werden in dieser Uebung aber nicht
  konfiguriert

## Ablauf am Beispiel Helm Chart

Ziel: Ein Helm Chart (z.B. traefik) deklarativ ausrollen.

Beteiligte Objekte:

1. `HelmRepository` - Chart-Repo als Quelle
2. `HelmRelease` - Release-Definition

**A) source-controller:**
1. `HelmRepository` wird reconciled: source-controller laedt `index.yaml`
   des Chart-Repos, speichert Status/Revision
2. Fuer eine `HelmRelease` wird intern ein `HelmChart`-Artifact erzeugt

**B) helm-controller:**
3. helm-controller reconciled die `HelmRelease`: holt das Chart-Artefakt,
   rendert Templates mit `values`, fuehrt intern ein `helm upgrade --install`
   aus
4. Status wird im `HelmRelease`-Objekt aktualisiert (Conditions, letzte
   erfolgreiche Revision)

**C) Wiederholung:**
5. Neue Chart-Version im Repo oder Werte-Aenderung -> naechster Reconcile
6. Flux sorgt dafuer, dass der Cluster-Zustand wieder dem gewuenschten
   Zustand entspricht

Die folgenden Uebungen bauen genau diesen Ablauf Schritt fuer Schritt auf:
Installation, `HelmRepository`, `HelmRelease`, `OCIRepository` und ein
eigenes Chart aus einem Git-Repo.
