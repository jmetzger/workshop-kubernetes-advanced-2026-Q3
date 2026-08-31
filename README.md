# Kubernetes - Modul Advanced

## Agenda

### Tag 1 - Networking & Security

  1. Kubernetes-Networking-Grundlagen
     * Netzwerk-Grundlagen & K8s-Networking-Modell
     * Funktionsweise CNI am Beispiel Calico
     * MetalLB als Load-Balancer fuer Bare-Metal

  1. Network Policies
     * Einfuehrung Standard-NetworkPolicies
     * Erweiterte Policies mit Calico

  1. RBAC & Identity
     * ServiceAccounts: Pod-Zugriff auf den API-Server
     * Roles, RoleBindings & ClusterRoles

  1. Secrets Management mit HashiCorp Vault
     * Einbindung via Vault Operator
     * Alternative: Vault Agent (Sidecar-Injection)

  1. Workload-Skalierung
     * Horizontal Pod Autoscaler (HPA)

### Tag 2 - Observability, Service Mesh & GitOps

  1. Monitoring & Logging
     * Monitoring mit Prometheus (Architektur & Funktionsweise)
     * Logging-Stack: Fluentd -> Elasticsearch
     * Alternative: Splunk-Integration

  1. Troubleshooting
     * kubectl debug fuer Pods und Nodes
     * Logs, Events & typische Fehlerbilder

  1. Service Mesh
     * Istio & Envoy verstehen
     * Praktischer Aufbau im Cluster
     * Vor- und Nachteile abwaegen

  1. GitOps - kurze Einfuehrung
     * ArgoCD vs. Flux CD im Ueberblick
     * Kleines Hands-on-Beispiel

  1. Abschluss
     * Best Practices & Hands-on Labs
     * Fehler vermeiden, Debugging meistern
