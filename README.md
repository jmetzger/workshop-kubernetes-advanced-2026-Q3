# Kubernetes - Modul Advanced

## Agenda

### Tag 1 - Networking & Security

  1. Vorbereitung
     * [kubectl Verbindung mit namespace einrichten](kubectl/kubectl-einrichten.md)
     * [Das Tool kubectl - Spickzettel](/kubectl/spickzettel.md)

  1. MetalLB als Load-Balancer (Bare-Metal)
     * [Kubernetes Load Balancer - metallb](metallb.md)
     * [Feste IP beziehen](/service/feste-ip-beziehen.md)

  1. Kubernetes-Networking-Grundlagen
     * [Networking Internal Overview](/kubernetes-networks/networking-internal-overview.md)
     * [Cluster-CIDR, POD-CIDR und Service-CIDR](kubernetes-networks/kubernetes-cidrs.md)
     * [Wann wird die PodIP vergeben?](kubectl/run-with-example.md)
     * [CNI - Wie funktioniert das unter der Haube](/kubernetes/internals/cni.md)
     * [Ueberblick CNI-Provider](kubernetes-networks/overview.md)
     * [CNI-Provider calico einrichten](kubernetes-networks/calico/installation/install-cni.md)
     * [Weg vom Pod zum Host -> veth / calicoctl get wep](kubernetes-networks/calico/find-corresponding-interfaces.md)

  1. Network Policies
     * [Einfache Uebung NetworkPolicy (Standard)](kubernetes-networkpolicy/00-simple-exercises-group.md)
     * [Beispiel mit ipBlock](kubernetes-networkpolicy/01-example-from-ipblock.md)
     * [Erweiterte Policies mit Calico - Uebung](kubernetes-networkpolicy/calico/01-exercise-calico.md)
     * [Calico - Services schuetzen](kubernetes-networkpolicy/calico/02-example-protecting-services.md)

  1. RBAC & Identity
     * [Least Privileges mit RBAC](kubernetes/rbac/00-rbac-and-least-privileges.md)
     * [Wie funktioniert RBAC?](kubernetes/rbac/01-how-does-rbac-work.md)
     * [Wo spielt RBAC eine Rolle?](kubernetes/rbac/02-where-does-rbac-play-a-role.md)
     * [kubectl - Berechtigungen pruefen mit can-i](kubernetes/rbac/can-i.md)
     * [ServiceAccounts: kubectl im Pod - default ServiceAccount](/kubernetes/rbac/pod-automount-sa.md)
     * [ServiceAccounts: Automount - ja oder nein?](security/serviceaccount/do-not-mount-if-not-needed.md)
     * [Praktische Uebung: User mit Zertifikat anlegen (kubeconfig)](kubernetes/rbac/create-kubeconfig-with-cert.md)
     * [Praktische Uebung RBAC (ab Kubernetes 1.25)](kubernetes/rbac-create-user-kubernetes-1-25.md)

  1. Secrets Management mit HashiCorp Vault / OpenBao
     * [HashiCorp Vault als Password-Safe (Overview)](security/hashicorp-vault/overview.md)
     * [Architektur-Ueberblick OpenBao](openbao/overview.md)
     * [Was sind Secret-Engines?](openbao/secret-engines.md)
     * [Server-Installation: Standalone hinter nginx Reverse Proxy](openbao/installation/standalone.md)
     * [User/Gruppe fuer Passwort-Authentifizierung aufsetzen](openbao/configuration/01-setup-userpass-for-user-with-group.md)
     * [Uebung Operator-Variante: MariaDB-Deployment mit Vault Secrets Operator (VSO)](openbao/configuration/02-kubernetes-to-openbao-eso-secrets.md)
     * [Uebung: MariaDB-Deployment mit echtem HashiCorp Vault ueber den Vault Secrets Operator (VSO)](hashicorp-vault/configuration/01-mariadb-vault-secrets-operator.md)
     * [Uebung: MariaDB-Deployment mit dem Vault Agent Injector](hashicorp-vault/configuration/02-mariadb-vault-agent-injector.md)

  1. Workload-Skalierung
     * [Autoscaling Pods/Deployments - Grundlagen](kubernetes/autoscaling.md)
     * [Uebung: Horizontal Pod Autoscaler (HPA)](kubernetes-autoscaling/hpa.md)

### Tag 2 - Observability, Service Mesh & GitOps

  1. Monitoring mit Prometheus
     * [Prometheus Monitoring Server (Overview)](prometheus/overview.md)
     * [Prometheus/Grafana-Stack installieren mit helm](prometheus-grafana/prometheus-grafana/install-with-helm-letsencrypt-basic-auth.md)
     * [Uebung: nginx mit ServiceMonitor und Exporter (Sidecar)](monitoring/praxis/03-nginx-servicemonitor.md)

  1. Logging-Stack: Fluentd -> Elasticsearch
     * [Fluentd - Grundlagen](kubernetes-monitoring/fluentd.md)
     * [Fluentd/Kibana/Elasticsearch - Walkthrough](microk8s/fluent-kibana-elastic-mit-microk8s.md)

  1. Alternative: Splunk-Integration
     * [Theorie: Kubernetes mit Splunk verbinden](kubernetes-splunk/UEBERSICHT.md)
     * [Funktionsuebersicht: Splunk-Menuepunkte und Kubernetes-Relevanz](kubernetes-splunk/menues-und-ihre-funktion.md)
     * [Log-Forwarder an externen Splunk-Server anbinden](kubernetes-splunk/uebungen/03-forwarder-an-externe-splunk.md)
     * [Abstuerzenden Pod ueber Splunk debuggen (CrashLoopBackOff)](kubernetes-splunk/uebungen/04-log-suche-crashloop-debugging.md)
     * [CrashLoopBackOff-Alert einrichten (optional)](kubernetes-splunk/uebungen/05-alert-crashloop-backoff.md)
     * [Optional: Splunk im Cluster betreiben (Splunk Operator)](kubernetes-splunk/uebungen/10-optional-splunk-operator-installieren.md)

  1. Troubleshooting
     * [Debugging von Pods (Logs, Events, typische Fehlerbilder)](tipps-tricks/debugging-pods.md)
     * [kubectl debug - Ephemeral Container](kubernetes-networks/debug-container.md)
     * [Host/Node erforschen mit kubectl debug (z.B. CNI)](debug/kubectl-debug-cni.md)
     * [ClusterIP debuggen](tipps-tricks/cluster-ip-debug.md)

  1. Service Mesh - Istio & Envoy verstehen
     * [Einfuehrung in Istio & Service-Mesh-Architekturen](/istio/overview/01-introduction.md)
     * [Warum ein Service Mesh?](istio/overview/02-warum-servicemesh.md)
     * [Herausforderungen & Vorteile](istio/overview/03-herausforderungen-vorteile.md)
     * [Architektur & Komponenten von Istio](istio/overview/04-architektur-komponenten.md)
     * [Istio Proxy-Konzepte (Envoy als Sidecar)](istio/overview/07-istio-proxy-concepts-sidecar.md)
     * [Vergleich mit Linkerd, Cilium, Consul](istio/overview/05-vergleich-linkerd-cilium-consul.md)

  1. Service Mesh - Praktischer Aufbau im Cluster
     * [Istio-Installation mit istioctl (demo-Profil)](istio/installation/03-install-with-istioctl-with-demo-profile.md)
     * [istioctl Cheatsheet zum Debuggen](/istio/istioctl-cheatsheet.md)
     * [Uebung: Sidecar-Injection](istio/exercises/01-exercise-injection.md)
     * [Demo-App bookinfo installieren](istio/installation/04-install-demo-app-bookinfo.md)
     * [Uebung: Header-basiertes Routing](istio/exercises/02-exercise-request-routing.md)
     * [Uebung: Traffic-Shifting / Load-Balancing](istio/exercises/04-traffic-shifting.md)
     * [Debugging mit debug/run pod](/istio/debug/01-debug-pod.md)

  1. GitOps mit Flux
     * [ArgoCD vs. Flux CD im Ueberblick](gitops/argocd-vs-flux.md)
     * [Flux Ueberblick - Controller, CRDs und Ablauf](gitops/flux/01-overview.md)
     * [Flux Installation und GitOps-Bootstrap mit GitLab](gitops/flux/02-installation.md)
     * [HelmRepository - Helm Chart Repositories verwalten](gitops/flux/03-helmrepository.md)
     * [HelmRelease - Helm Charts deklarativ ausrollen](gitops/flux/04-helmrelease.md)
     * [OCI-Helm-Chart verwenden](gitops/flux/05-oci-helm-chart.md)
     * [Eigenes Helm Chart aus Git-Repository ausrollen](gitops/flux/06-eigenes-helmchart.md)

  1. Abschluss
     * Best Practices & Hands-on Labs
     * Fehler vermeiden, Debugging meistern
