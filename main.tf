provider "digitalocean" {
}

resource "digitalocean_ssh_key" "web" {
  name       = "Web app SSH key"
  public_key = file("${path.module}/files/id_rsa.pub")
}

resource "digitalocean_droplet" "web" {
  count              = 2
  image              = "ubuntu-19-10-x64"
  name               = "web-${count.index}"
  region             = "lon1"
  size               = "s-1vcpu-1gb"
  monitoring         = true
  private_networking = true
  ssh_keys = [
    digitalocean_ssh_key.web.id
  ]
  user_data = file("${path.module}/files/user-data.sh")
}

resource "digitalocean_certificate" "web" {
  name    = "web-certificate"
  type    = "lets_encrypt"
  domains = ["simple-coding.co.uk"]
}

resource "digitalocean_loadbalancer" "web" {
  name   = "web-lb"
  region = "lon1"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8080
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 8080
    target_protocol = "http"

    certificate_id = digitalocean_certificate.web.id
  }

  healthcheck {
    port     = 8080
    protocol = "http"
    path     = "/"
  }

  redirect_http_to_https = true
  droplet_ids            = digitalocean_droplet.web.*.id
}

resource "digitalocean_domain" "domain" {
  name = "simple-coding.co.uk"
}

resource "digitalocean_record" "main" {
  domain = digitalocean_domain.domain.name
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.web.ip
}
