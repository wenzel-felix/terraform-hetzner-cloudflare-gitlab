module "gitlab" {
  source               = "../.."
  cloudflare_token     = var.cloudflare_token
  cloudflare_zone_id   = var.cloudflare_zone_id
  hetzner_token        = var.hetzner_token
  hetzner_network_zone = var.hetzner_network_zone
  hetzner_datacenter   = var.hetzner_datacenter
  # network_id = "2560599"
  zone = var.dns_zone
}

output "name" {
  value = module.gitlab.root_password
}