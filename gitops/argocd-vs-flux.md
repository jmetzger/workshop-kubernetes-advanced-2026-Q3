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
| Bootstrapping | Manuell oder argocd-autopilot | flux bootstrap (legt Repo-Struktur an) |
| Typische Zielgruppe | Teams, die eine UI fuer Devs/Ops wollen | Plattform-Teams, die alles deklarativ/headless wollen |

## Wann was?

  * **ArgoCD**: Wenn eine grafische Oberflaeche fuer Sync-Status, Diffs und
    Rollbacks gewuenscht ist und mehrere Teams/Cluster zentral bedient werden
    sollen. Einstieg ist visuell und schnell verstaendlich.
  * **Flux CD**: Wenn alles rein deklarativ ohne UI laufen soll, Helm-Releases
    "richtig" (mit Helm-Lifecycle) verwaltet werden sollen oder automatische
    Image-Updates gewuenscht sind.

Beide loesen dasselbe Grundproblem - die Wahl ist meist eine Frage von
UI-Bedarf, Team-Struktur und vorhandener Toolchain.

## Weiter geht es praktisch

  * [Was ist ArgoCD?](/istio/argocd/was-ist-argocd.md)
  * [Hands-on: Deployment mit ArgoCD](/istio/argocd/argocd-istio-bookinfo.md)
