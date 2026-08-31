variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "fra1"
}

variable "droplet_size" {
  description = "Droplet size fuer den externen Splunk-Server"
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "ssh_key_id" {
  description = "DO SSH-Key-ID (claude-code-testing)"
  type        = string
  default     = "53105908"
}

variable "vpc_uuid" {
  description = "VPC, in der auch der DOKS-Cluster (splunk-training) und der Bastion laufen - noetig fuer privaten Netzwerkzugriff des Log-Forwarders auf HEC"
  type        = string
  default     = "fa374b13-dc84-11e8-8b13-3cfdfea9f160"
}

variable "vpc_cidr" {
  description = "CIDR der VPC, fuer die Firewall-Freigabe von HEC (Port 8088)"
  type        = string
  default     = "10.135.0.0/16"
}

variable "splunk_admin_password" {
  description = "Initiales Admin-Passwort fuer die externe Splunk-Instanz (via user-seed.conf gesetzt)"
  type        = string
  sensitive   = true
}

variable "splunk_hec_token" {
  description = "HEC-Token, den die externe Splunk-Instanz von Anfang an verwendet (selbst gewaehlt statt auto-generiert)"
  type        = string
  sensitive   = true
}

variable "splunk_version" {
  description = "Splunk Enterprise Version"
  type        = string
  default     = "10.4.2"
}

variable "splunk_deb_url" {
  description = "Direkter Download-Link zum Splunk Enterprise .deb Paket"
  type        = string
  default     = "https://download.splunk.com/products/splunk/releases/10.4.2/linux/splunk-10.4.2-33c3bf42cd73-linux-amd64.deb"
}

variable "admin_email" {
  description = "E-Mail fuer die Let's-Encrypt-Zertifikatsregistrierung (certbot)"
  type        = string
  default     = "j.metzger@t3company.de"
}
