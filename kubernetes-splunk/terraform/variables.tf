variable "kubeconfig_path" {
  description = "Pfad zur kubeconfig des DOKS-Clusters (siehe digitalocean/download-kubeconfig-to-bastion.sh)"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Namespace fuer Splunk Operator + Splunk Enterprise"
  type        = string
  default     = "splunk-operator"
}

variable "splunk_operator_crd_url" {
  description = "URL der Splunk Operator CRD-Manifeste (Helm kann diese wegen 1MB-Limit nicht ausliefern)"
  type        = string
  default     = "https://github.com/splunk/splunk-operator/releases/download/3.1.0/splunk-operator-crds.yaml"
}
