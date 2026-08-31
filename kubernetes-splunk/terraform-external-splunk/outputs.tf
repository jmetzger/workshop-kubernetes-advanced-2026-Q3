output "public_ip" {
  value = digitalocean_droplet.splunk_external.ipv4_address
}

output "private_ip" {
  value = digitalocean_droplet.splunk_external.ipv4_address_private
}

output "next_steps" {
  value = <<-EOT
    Externe Splunk-VM erstellt: ${digitalocean_droplet.splunk_external.name}
      Public IP:  ${digitalocean_droplet.splunk_external.ipv4_address}
      Private IP: ${digitalocean_droplet.splunk_external.ipv4_address_private}
      DNS:        splunk-external.do.t3isp.de (nach Cloud-Init, ca. 5-10 Min)

    Web-UI erreichen (Nginx-Reverse-Proxy mit Let's-Encrypt-Zertifikat, Port 8000 selbst
    bleibt intern/firewalled):
      https://splunk-external.do.t3isp.de

    HEC-Endpoint fuer den Log-Forwarder im Kubernetes-Cluster (oeffentlich erreichbar,
    abgesichert nur durch den Token - private VPC-Routing funktioniert wegen Cilium/DOKS
    Pod-Masquerading nicht, siehe cloud-init-splunk-external.sh.tpl):
      https://splunk-external.do.t3isp.de:8088/services/collector
  EOT
}
