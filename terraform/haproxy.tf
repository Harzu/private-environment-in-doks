resource "digitalocean_droplet" "haproxy" {
    image    = "ubuntu-20-04-x64"
    name     = "haproxy"
    region   = "ams3"
    size     = "s-1vcpu-2gb"
    vpc_uuid = digitalocean_vpc.private.id
    ssh_keys = [digitalocean_ssh_key.root_key.fingerprint]
}

resource "digitalocean_record" "haproxy" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "haproxy"
    ttl    = 300
    value  = digitalocean_droplet.haproxy.ipv4_address_private
}
