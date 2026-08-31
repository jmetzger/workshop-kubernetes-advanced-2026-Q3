# CLAUDE.md - workshop-kubernetes-advanced-2026-Q3

## Was ist das hier

Trainings-Repo "Kubernetes - Modul Advanced" (2 Trainingstage) fuer ein
Inhouse-Training im September 2026. Schwester-Repo: `workshop-kubernetes-basics-2026-Q3`
(Modul Basics). Dieses Repo ist PUBLIC und enthaelt bewusst keinen Kundenbezug -
auch in Commits, Dateien und Issues keinen Kundennamen nennen.

Die README.md ist die Agenda des Trainings (Tag 1: Networking & Security,
Tag 2: Observability, Service Mesh & GitOps) - alle Uebungen sind dort verlinkt.

## Trainingsumgebung

- Jeder Teilnehmer hat in diesem Modul ein EIGENES Cluster.
- Namespaces in Uebungen daher fest (ohne `<dein-name>`-Suffix) moeglich;
  Uebungen aus geteilten Quell-Repos nutzen teils `<prefix>-<dein-name>` - beides ok.
- Zugang per Putty/SSH oder Chrome (Guacamole) auf Bastion-Client.

## Woher die Inhalte kommen (Stand 31.08.2026)

| Verzeichnis | Quelle |
|-------------|--------|
| kubernetes-networks/, kubectl/, kubectl-examples/, kubernetes-networkpolicy/, calico/, debug/, service/, metallb.md, kubernetes/ (Basis) | training-kubernetes-networking |
| kubernetes/rbac/, kubernetes/rbac-create-user-kubernetes-1-25.md, security/ | training-kubernetes-security |
| openbao/ | training-openbao-kubernetes |
| prometheus/, prometheus-grafana/, monitoring/, kubernetes-autoscaling/, kubernetes-monitoring/, microk8s/ | training-kubernetes-monitoring |
| istio/ (inkl. istio/argocd/) | training-istio-kubernetes |
| tipps-tricks/, kubernetes/autoscaling.md | training-kubernetes-advanced |
| kubernetes-splunk/ | workshop-kubernetes-advanced-2026-modul1 (anderes Training, nur Splunk-Teil uebernommen) |
| gitops/argocd-vs-flux.md | neu geschrieben (Theorie-Uebersicht) |

Aenderungen an Uebungen bitte HIER machen, nicht in den Quell-Repos -
dieses Repo ist die fuer das Training massgebliche Kopie.

## Offene Punkte

- Vault/OpenBao: Operator-Variante (VSO) ist als Uebung da; eine explizite
  Sidecar/Agent-Injection-Uebung fehlt noch (wuerde Neubau + Cluster-Test brauchen).
- README-Punkt "Abschluss" hat bewusst keine Links (freier Teil).

## Konventionen (Kurzfassung Skill workshop-training)

- Keine Umlaute in neuen Dateien (ae/oe/ue/ss), Dateiendung `.yml`, Manifests nummerieren.
- Code-Bloecke ohne Sprach-Annotation, Namespace beim `kubectl apply -n ...` angeben, nicht im Manifest.
- Neue Uebungen MUESSEN auf einem echten Cluster getestet werden, bevor sie in die Agenda kommen.
- Jede neue Uebung in der README-Agenda verlinken.
- Link-Check: `grep -oE '\]\(([^)]+)\)' README.md | sed 's/](\(.*\))/\1/' | grep -v '^http' | sed 's|^/||' | while read f; do [ -f "$f" ] || echo "MISSING: $f"; done`
- PDF: `gh workflow run pdf-deployment.yml --repo jmetzger/github-md2pdf --field repository=workshop-kubernetes-advanced-2026-Q3`
