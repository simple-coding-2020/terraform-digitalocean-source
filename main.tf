provider "digitalocean" {
}

resource "digitalocean_ssh_key" "web" {
  name       = "Web app SSH key"
  public_key = file("${path.module}/files/id_rsa.pub")
}

resource "digitalocean_database_cluster" "db" {
  name       = "web-db"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "lon1"
  node_count = 1
}

resource "digitalocean_database_firewall" "db-fw" {
  cluster_id = digitalocean_database_cluster.db.id

  rule {
    type  = "tag"
    value = digitalocean_tag.web.id
  }
}

resource "digitalocean_database_user" "db-user" {
  cluster_id        = digitalocean_database_cluster.db.id
  name              = "web-user"
  mysql_auth_plugin = "mysql_native_password"
}

resource "digitalocean_tag" "web" {
  name = "web-app"
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
  user_data = templatefile("${path.module}/files/user-data.sh", {
    host     = digitalocean_database_cluster.db.private_host,
    user     = "web-user",
    database = digitalocean_database_cluster.db.database,
    password = digitalocean_database_user.db-user.password,
    port     = digitalocean_database_cluster.db.port
  })
  tags = [digitalocean_tag.web.id]
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

resource "digitalocean_firewall" "web" {
  name = "web-droplet-firewall"

  droplet_ids = digitalocean_droplet.web.*.id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "8080"
    source_load_balancer_uids = [digitalocean_loadbalancer.web.id]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
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
