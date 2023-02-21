terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_token
}

locals {
  IP_range      = "10.0.0.0/16"
  domain_prefix = "my"
}

resource "hcloud_network" "network" {
  name     = "network"
  ip_range = local.IP_range
}

resource "hcloud_network_subnet" "network" {
  network_id   = hcloud_network.network.id
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
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "hcloud_server" "main" {
  depends_on = [
    hcloud_network_subnet.network
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
    network_id = hcloud_network.network.id
  }

  user_data = templatefile("${path.module}/scripts/base_configuration.sh", {
    GITLAB_ROOT_PASSWORD = random_password.password.result,
    EXTERNAL_URL         = "https://${local.domain_prefix}.hetznerdoesnot.work"
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
      port        = "42069"
    }
  }
}

output "root_password" {
  value = nonsensitive(random_password.password.result)
}
