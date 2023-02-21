variable "hetzner_token" {}
variable "hetzner_network_zone" {
  type        = string
  description = "Hetzner Cloud Network Zone"
  default     = "eu-central"
}
variable "hetzner_datacenter" {
  type        = string
  description = "Hetzner Cloud Datacenter"
  default     = "hel1"
}
variable "cloudflare_zone_id" {}
variable "cloudflare_token" {}