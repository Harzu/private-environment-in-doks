resource "digitalocean_kubernetes_cluster" "primary" {
  name          = "primary"
  region        = "ams3"
  version       = "1.28.2-do.0"
  vpc_uuid      = digitalocean_vpc.private.id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb"
    node_count = 1
  }
}

resource "digitalocean_record" "pgadmin" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "pgadmin"
    value  = digitalocean_droplet.haproxy.ipv4_address_private
}
