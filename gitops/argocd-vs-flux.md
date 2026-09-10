# GitOps - ArgoCD vs. Flux CD im Ueberblick

## Hintergrund

GitOps bedeutet: Der gewuenschte Zustand des Clusters liegt versioniert in Git.
Ein Controller im Cluster vergleicht laufend Soll (Git) und Ist (Cluster) und
gleicht Abweichungen automatisch ab (Reconciliation).

```
Git-Repo (Soll)  <---- pull ----  GitOps-Controller im Cluster  ----> Cluster (Ist)
```

Vorteile:

  * Nachvollziehbarkeit: Jede Aenderung ist ein Commit (Audit-Trail)
  * Rollback = git revert
  * Kein kubectl apply von Entwickler-Rechnern noetig (Pull- statt Push-Prinzip)
  * Drift-Erkennung: manuelle Aenderungen im Cluster werden erkannt (und je nach Konfiguration zurueckgesetzt)

## Die beiden grossen Player

| Kriterium | ArgoCD | Flux CD |
|-----------|--------|---------|
| Projekt-Status | CNCF Graduated | CNCF Graduated |
| Web-UI | Ja, sehr ausgereift (Sync-Status, Diff, Rollback per Klick) | Nein (nur CLI; UIs von Drittanbietern, z.B. Weave GitOps) |
| CLI | argocd | flux |
| Kern-Konzept | Application (CRD) zeigt auf Repo/Pfad | GitRepository + Kustomization / HelmRelease (CRDs) |
| Helm-Support | Ja (rendert Charts zu Manifests) | Ja (HelmRelease mit echtem helm install/upgrade) |
| Multi-Cluster | Ja, zentrale Instanz kann viele Cluster bedienen | Ja, ueblicherweise 1 Flux pro Cluster |
| Multi-Tenancy | Projects, RBAC, SSO in der UI | ueber Kubernetes-RBAC und Namespaces |
| Image-Update-Automation | Separates Projekt (argocd-image-updater) | Eingebaut (Image Automation Controller) |
| Bootstrapping | Manuell (`kubectl apply` des Install-Manifests) oder argocd-autopilot | `flux bootstrap` (imperativer CLI-Befehl) oder Flux Operator + `FluxInstance` (deklarativ, **empfohlen** - siehe [Installation](flux/02-installation.md)) |
| Selbst-Update (Tool + Version) | Kein eingebauter Mechanismus - ArgoCD wird klassisch per Manifest/Helm aktualisiert. Es gibt einen [argocd-operator](https://github.com/argoproj-labs/argocd-operator) (argoproj-labs, v.a. Basis fuer Red Hats OpenShift GitOps): vereinfacht die Installation ueber eine `ArgoCD`-CRD, **aber** `spec.version` ist ein fest gepinnter Image-Tag (kein Semver-Range-Autotracking wie bei Flux), und Operator-Selbst-Update gibt es nur ueber einen **OLM**-Auto-Update-Channel - OLM ist primaer ein OpenShift-Mechanismus, auf vanilla Kubernetes (wie unseren Clustern) zusaetzlicher Aufwand | Flux Operator haelt sowohl die Flux-Version (`FluxInstance.spec.distribution.version: "2.x"`) als auch sich selbst (per eigener `HelmRelease`) automatisch aktuell - kein wiederkehrender `flux bootstrap`- oder `helm upgrade`-Lauf noetig, siehe [Installation](flux/02-installation.md) |
| Typische Zielgruppe | Teams, die eine UI fuer Devs/Ops wollen | Plattform-Teams, die alles deklarativ/headless wollen |

## Wann was?

Ist das reine Geschmackssache? **Nein** - beide loesen das GitOps-Grundproblem
gleich gut, aber es gibt reale technische Unterschiede, die die Wahl in
konkreten Situationen vorwegnehmen. Nur ein Teil der Entscheidung ist
tatsaechlich Praeferenz.

**Fuer ArgoCD spricht:**

  * Eine Web-UI fuer Sync-Status, Diff und Rollback wird gebraucht (Devs ohne
    CLI-Affinitaet, Trainings/Demos, schnelles visuelles Troubleshooting)
  * Eine zentrale Instanz soll viele Teams/Cluster mit RBAC/SSO bedienen
    (App Projects) - ein Ops-Team behaelt die UI-Uebersicht ueber alles
  * PR-basierte Review-Workflows, bei denen der Diff am Ende auch visuell
    bestaetigt werden soll
  * Kubernetes-/GitOps-Neulinge im Team - die UI senkt die Einstiegshuerde
    gegenueber "nur CLI + `kubectl get kustomization`" erheblich

**Fuer Flux CD spricht - und mit Flux Operator noch mehr:**

  * Komplett deklarativ/headless gewuenscht, keine zusaetzliche UI-Komponente
    im Cluster
  * Die Plattform soll sich selbst warten: Der Flux Operator haelt sowohl die
    Flux-Version als auch sich selbst automatisch aktuell, ohne dass jemand
    `flux bootstrap` erneut anstossen oder ein manuelles `helm upgrade` fahren
    muss (siehe [Installation](flux/02-installation.md)). Das zahlt sich
    besonders aus, wenn es **viele gleichartige Cluster** gibt (wie hier: ein
    Cluster pro Teilnehmer) - zentrale, manuelle Wartung pro Cluster skaliert
    dann nicht
  * Helm-Releases sollen "echt" mit Helm-Lifecycle laufen (nicht nur
    gerenderte Manifeste wie bei ArgoCD)
  * Automatische Image-Updates ohne Zusatzprojekt gewuenscht

**Tatsaechlich Geschmackssache/Kontext:**

  * Multi-Tenancy: beide loesen das (ArgoCD ueber Projects+RBAC in der UI,
    Flux ueber Kubernetes-Bordmittel/Namespaces) - was passender ist, haengt
    vom bereits vorhandenen RBAC-Modell im Team ab
  * Vorhandenes Know-how/Toolchain im Team (schon Erfahrung mit dem einen
    oder anderen Tool vorhanden)

## Fazit

Der Flux Operator veraendert vor allem die **Betriebs-Story** von Flux
(Selbstwartung von Tool und Version), nicht das GitOps-Grundprinzip selbst.
Wer eine UI braucht oder zentral viele Cluster/Teams bedienen muss, greift
weiterhin eher zu ArgoCD. Wer moeglichst wenig manuellen Betriebsaufwand fuer
das GitOps-Tool selbst haben will - kein wiederkehrendes `flux bootstrap`,
kein manuelles Upgrade des Tools - fuer den macht der Flux Operator Flux CD
gegenueber ArgoCD noch einmal deutlicher attraktiver als vorher.

## Weiter geht es praktisch

  * [Flux Ueberblick - Controller, CRDs und Ablauf](flux/01-overview.md)
  * [Flux Installation mit dem Flux Operator](flux/02-installation.md)
  * [Was ist ArgoCD?](/istio/argocd/was-ist-argocd.md)
  * [Hands-on: Deployment mit ArgoCD](/istio/argocd/argocd-istio-bookinfo.md)
