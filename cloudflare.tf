provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "app" {
  zone_id = var.cloudflare_zone_id
  name    = local.main_subdomain
  value   = cloudflare_tunnel.gitlab.cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# resource "cloudflare_record" "ssh" {
#   zone_id = var.cloudflare_zone_id
#   name    = local.ssh_subdomain
#   value   = "${cloudflare_tunnel.gitlab.cname}"
#   type    = "CNAME"
#   proxied = true
#   ttl = 1
# }

resource "cloudflare_record" "registry" {
  zone_id = var.cloudflare_zone_id
  name    = local.registry_subdomain
  value   = cloudflare_tunnel.gitlab.cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_tunnel" "gitlab" {
  account_id = "6b4c83722ad8306ddc86dee9d87f4d0a"
  name       = "gitlab"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_tunnel_config" "gitlab" {
  account_id = "6b4c83722ad8306ddc86dee9d87f4d0a"
  tunnel_id  = cloudflare_tunnel.gitlab.id

  config {
    # 65.109.234.204
    ingress_rule {
      hostname = "${local.main_subdomain}.${var.dns_zone}"
      service  = "http://localhost:80"
    }
    # ingress_rule {
    #   hostname = "${local.ssh_subdomain}.${var.dns_zone}"
    #   service  = "ssh://localhost:22"
    # }
    ingress_rule {
      hostname = "${local.registry_subdomain}.${var.dns_zone}"
      service  = "http://localhost:5005"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}