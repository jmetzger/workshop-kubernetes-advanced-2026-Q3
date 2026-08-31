provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "splunk_external" {
  name     = "splunk-external"
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-24-04-x64"
  vpc_uuid = var.vpc_uuid
  ssh_keys = [var.ssh_key_id]

  user_data = templatefile("${path.module}/cloud-init-splunk-external.sh.tpl", {
    splunk_admin_password = var.splunk_admin_password
    splunk_hec_token       = var.splunk_hec_token
    splunk_deb_url         = var.splunk_deb_url
    do_token               = var.do_token
    vpc_cidr                = var.vpc_cidr
    admin_email             = var.admin_email
  })
}
