provider "digitalocean" {
}

resource "digitalocean_ssh_key" "web" {
  name       = "Web app SSH key"
  public_key = file("${path.module}/files/id_rsa.pub")
}

resource "digitalocean_droplet" "web" {
  image              = "ubuntu-19-10-x64"
  name               = "testing"
  region             = "lon1"
  size               = "s-1vcpu-1gb"
  monitoring         = true
  private_networking = true
  ssh_keys = [
    digitalocean_ssh_key.web.id
  ]
  user_data = file("${path.module}/files/user-data.sh")
}
