output "namespace" {
  value = var.namespace
}

output "next_steps" {
  value = <<-EOT
    Splunk Operator + Standalone (S1) sind ueber Helm deployt.
    Status pruefen:
      kubectl --kubeconfig=${var.kubeconfig_path} get pods -n ${var.namespace}
    Admin-Passwort holen (siehe uebungen/12-optional-splunk-ui-zugriff-in-cluster.md):
      kubectl --kubeconfig=${var.kubeconfig_path} get secret -n ${var.namespace} splunk-stdln-standalone-secret-v1 -o jsonpath='{.data.password}' | base64 -d
  EOT
}
