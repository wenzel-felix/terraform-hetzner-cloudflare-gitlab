provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "main_ipv4" {
  zone_id = var.cloudflare_zone_id
  name    = local.domain_prefix
  value   = hcloud_server.main.ipv4_address
  type    = "A"
  #proxied = true
  ttl = 1500
}

resource "cloudflare_record" "main_ipv6" {
  zone_id = var.cloudflare_zone_id
  name    = local.domain_prefix
  value   = hcloud_server.main.ipv6_address
  type    = "AAAA"
  #proxied = true
  ttl = 1500
}