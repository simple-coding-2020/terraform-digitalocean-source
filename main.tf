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

resource "digitalocean_domain" "domain" {
  name = "simple-coding.co.uk"
}

resource "digitalocean_record" "main" {
  domain = digitalocean_domain.domain.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.web.0.ipv4_address
}
