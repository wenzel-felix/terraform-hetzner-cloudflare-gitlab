# Terraform-hetzner-gitlab
This module allows you to deploy a simple GitLab server on Hetzner with DNS managed by Cloudflare.
We are utilizing Cloudflare as a proxy by provisioning a Cloudflare tunnel on the GitLab server. Through this there are no rate limits that apply for creating new certificates as it would be the case for Let's Encrypt.

## Known Problems
Due to the Cloudflare proxy setup the solution does not support any ssh commands dependent on DNS resolution due to proxy limitations.
This mainly impacts direct ssh connections to the machine, which therefore can only be made via the public ip, as well as ssh based git cloning.