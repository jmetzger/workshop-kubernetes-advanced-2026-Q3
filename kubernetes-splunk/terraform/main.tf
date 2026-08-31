provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# CRDs sind >1MB, Helm kann sie nicht ausliefern -> separat per kubectl apply
resource "null_resource" "splunk_operator_crds" {
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${var.kubeconfig_path} apply --server-side -f ${var.splunk_operator_crd_url}"
  }
}

resource "helm_release" "splunk_operator" {
  name             = "splunk-operator-test"
  repository       = "https://splunk.github.io/splunk-operator/"
  chart            = "splunk-operator"
  namespace        = var.namespace
  create_namespace = true

  # Splunk General Terms muessen akzeptiert werden, sonst bleibt jede Standalone/Cluster CR
  # im Status "Error: license not accepted"
  set {
    name  = "splunkOperator.splunkGeneralTerms"
    value = "--accept-sgt-current-at-splunk-com"
  }

  depends_on = [null_resource.splunk_operator_crds]
}

resource "helm_release" "splunk_enterprise" {
  name       = "splunk-enterprise-test"
  repository = "https://splunk.github.io/splunk-operator/"
  chart      = "splunk-enterprise"
  namespace  = var.namespace

  # Der Chart-Wert fuer eine Single-Instance-Standalone liegt unter sva.s1, nicht s1
  set {
    name  = "sva.s1.enabled"
    value = "true"
  }

  # splunk-enterprise bringt den Operator als Dependency mit (splunk-operator.enabled: true
  # per Default) - da wir ihn oben schon separat installiert haben, muss das hier aus sein,
  # sonst kollidiert die ServiceAccount-Ownership zwischen beiden Helm-Releases
  set {
    name  = "splunk-operator.enabled"
    value = "false"
  }

  depends_on = [helm_release.splunk_operator]
}
