resource "digitalocean_droplet" "wireguard" {
    image    = "ubuntu-20-04-x64"
    name     = "wireguard"
    region   = "ams3"
    size     = "s-1vcpu-2gb"
    vpc_uuid = digitalocean_vpc.private.id
    ssh_keys = [digitalocean_ssh_key.root_key.fingerprint]
}

resource "digitalocean_record" "wireguard" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "wg"
    ttl    = 300
    value  = digitalocean_droplet.wireguard.ipv4_address
}

resource "digitalocean_record" "wireguard_ui" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "wg-ui"
    ttl    = 300
    value  = digitalocean_droplet.wireguard.ipv4_address_private
}

resource "digitalocean_firewall" "wireguard" {
    name = "wireguard"

    droplet_ids = [digitalocean_droplet.wireguard.id]

    # HTTP(S)
    inbound_rule {
        protocol         = "tcp"
        port_range       = "80"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }

    inbound_rule {
        protocol         = "tcp"
        port_range       = "443"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }

    # WireGuard
    inbound_rule {
        protocol         = "udp"
        port_range       = "51820"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }

    # ICMP
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
