terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_token
}

locals {
  IP_range           = "10.0.0.0/16"
  main_subdomain     = "gitlab"
  registry_subdomain = "registry"
  ssh_subdomain      = "gitlab"
}

resource "hcloud_network" "network" {
  count    = var.network_id == null ? 1 : 0
  name     = "network"
  ip_range = local.IP_range
}

resource "hcloud_network_subnet" "network" {
  count        = var.network_id == null ? 1 : 0
  network_id   = hcloud_network.network[0].id
  type         = "cloud"
  network_zone = var.hetzner_network_zone
  ip_range     = local.IP_range
}

resource "tls_private_key" "machines" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "default" {
  name       = "gitlb ssh key"
  public_key = tls_private_key.machines.public_key_openssh
}

resource "local_file" "name" {
  filename        = "private_key.pem"
  content         = tls_private_key.machines.private_key_pem
  file_permission = "0600"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [cloudflare_tunnel_config.gitlab]

  destroy_duration = "20s"
}

resource "hcloud_server" "main" {
  depends_on = [
    hcloud_network_subnet.network,
    time_sleep.wait_30_seconds
  ]
  name        = "gitlab-instance"
  server_type = var.server_type
  image       = "ubuntu-20.04"
  location    = var.hetzner_datacenter
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels = {
    "server-type" = "gitlab"
  }

  network {
    network_id = var.network_id == null ? hcloud_network.network[0].id : var.network_id
  }

  user_data = templatefile("${path.module}/scripts/base_configuration.sh", {
    EXTERNAL_URL  = "https://${local.main_subdomain}.${var.dns_zone}"
    ACCOUNT_ID    = var.cf_account_id
    TUNNEL_ID     = cloudflare_tunnel.gitlab.id
    TUNNEL_NAME   = cloudflare_tunnel.gitlab.name
    TUNNEL_SECRET = cloudflare_tunnel.gitlab.secret
    GITLAB_CONFIG = templatefile("${path.module}/templates/gitlab.rb.template", {
      EXTERNAL_URL          = "https://${local.main_subdomain}.${var.dns_zone}"
      REGISTRY_EXTERNAL_URL = "https://${local.registry_subdomain}.${var.dns_zone}"
      GITLAB_ROOT_PASSWORD  = random_password.password.result
      #GITLAB_SSH_HOST       = "${local.ssh_subdomain}.${var.dns_zone}"
    })
  })

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = tls_private_key.machines.private_key_openssh
    }
  }
}

output "root_password" {
  value = nonsensitive(random_password.password.result)
}
