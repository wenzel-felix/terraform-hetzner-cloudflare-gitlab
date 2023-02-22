module "gitlab" {
  source               = "../.."
  cloudflare_token     = var.cloudflare_token
  cloudflare_zone_id   = var.cloudflare_zone_id
  hetzner_token        = var.hetzner_token
  hetzner_network_zone = var.hetzner_network_zone
  hetzner_datacenter   = var.hetzner_datacenter
  # network_id = "2560599"
  dns_zone      = var.dns_zone
  cf_account_id = var.cf_account_id
}

output "name" {
  value = module.gitlab.root_password
}