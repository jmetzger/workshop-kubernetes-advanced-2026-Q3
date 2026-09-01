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
| gitops/flux/ | adaptiert aus jmetzger/workshop-kubernetes-helmholtz -> gitops/flux/, umgebaut auf GitLab-Bootstrap-Flow (kein Helm-Install, kein kubectl apply fuer GitOps-Objekte) und auf dem kubeadm-Testcluster verifiziert |

Aenderungen an Uebungen bitte HIER machen, nicht in den Quell-Repos -
dieses Repo ist die fuer das Training massgebliche Kopie.

## Offene Punkte

- **Uncommitted:** Der komplette FluxCD-Umbau (CLAUDE.md, README.md,
  `.gitignore`, `gitops/flux/*`) liegt noch unversioniert im Working Tree
  (Stand 31.08.2026, `git status --short` zeigt `M CLAUDE.md`, `M README.md`,
  `?? .gitignore`, `?? gitops/flux/`) - noch nicht committed/gepusht, da
  nicht explizit angefragt.
- Testcluster `tln1` (Projekt `intern`, siehe [[intern-kubeadm-testcluster]] in
  der User-Memory) laeuft noch auf DigitalOcean und kostet weiter Geld -
  Abbau war am Ende der FluxCD-Session noch offen, nicht vergessen.
- `flux uninstall`-Fix (siehe unten) ist nur einzeln verifiziert, nicht in
  einem kompletten Bootstrap-bis-Uninstall-Durchlauf end-to-end nachgetestet
  (optional, nicht blockierend - der Finalizer-Mechanismus dahinter ist
  verstanden).
- Vault/OpenBao: Operator-Variante (VSO) ist als Uebung da; eine explizite
  Sidecar/Agent-Injection-Uebung fehlt noch (wuerde Neubau + Cluster-Test brauchen).
- README-Punkt "Abschluss" hat bewusst keine Links (freier Teil).
- NFS-basierte StorageClass fuer die kubeadm-Trainingscluster (in-Cluster
  NFS-Server vs. zentraler Droplet pro Training) noch nicht entschieden.
  Aktuelle Uebungen (z.B. gitops/flux/05-oci-helm-chart.md) umgehen das
  bewusst mit `persistence.enabled: false`.

## GitOps-Kapitel (Tag 2) - FluxCD

Umgebaut und getestet (Stand 31.08.2026): ArgoCD-Hands-on
(`istio/argocd/was-ist-argocd.md`, `istio/argocd/argocd-istio-bookinfo.md`)
ist aus der Agenda raus, `gitops/flux/` (6 Uebungen) ist drin. Jeder
Teilnehmer nutzt seinen eigenen gitlab.com-Account (`training.tn<nr>`,
vom Trainer vorab angelegt) fuer `flux bootstrap gitlab` - danach laeuft
alles ueber `git commit`/`push`, kein `kubectl apply` mehr fuer die
GitOps-Objekte selbst. Getestet auf einem kubeadm-Testcluster
(Skill `training-kubeadm-cluster`).

**Wichtig beim Aufraeumen:** `flux uninstall --namespace=flux-system`
verwenden, NICHT `kubectl delete namespace flux-system` gefolgt von
`kubectl delete crds ...` - letzteres kann zu einem Finalizer-Deadlock
fuehren (Controller-Pods verschwinden, bevor sie Finalizer auf uebrig
gebliebenen Custom Resources entfernt haben -> Namespace haengt fuer immer
in `Terminating`).

## Secrets-Handling

Dieses Repo ist PUBLIC und haelt bewusst KEINE eigenen Secrets (kein
`.env.enc` hier). Tokens fuer Uebungen mit externen Diensten (z.B.
`GITLAB_PAT` fuer den FluxCD-Bootstrap) liegen verschluesselt im separaten
intern-Infra-Repo. `.env`/`.env.enc` stehen in `.gitignore`, falls doch mal
kurzzeitig eine Klartext-`.env` hier landet (z.B. zum Token-Uebergeben) -
danach wieder loeschen, niemals committen.

## Konventionen (Kurzfassung Skill workshop-training)

- Keine Umlaute in neuen Dateien (ae/oe/ue/ss), Dateiendung `.yml`, Manifests nummerieren.
- Code-Bloecke ohne Sprach-Annotation, Namespace beim `kubectl apply -n ...` angeben, nicht im Manifest.
- Neue Uebungen MUESSEN auf einem echten Cluster getestet werden, bevor sie in die Agenda kommen.
- Jede neue Uebung in der README-Agenda verlinken.
- Link-Check: `grep -oE '\]\(([^)]+)\)' README.md | sed 's/](\(.*\))/\1/' | grep -v '^http' | sed 's|^/||' | while read f; do [ -f "$f" ] || echo "MISSING: $f"; done`
- PDF: `gh workflow run pdf-deployment.yml --repo jmetzger/github-md2pdf --field repository=workshop-kubernetes-advanced-2026-Q3`
