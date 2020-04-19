provider "digitalocean" {
}

resource "digitalocean_droplet" "web" {
  image  = "ubuntu-19-10-x64"
  name   = "testing"
  region = "lon1"
  size   = "s-1vcpu-1gb"
}
