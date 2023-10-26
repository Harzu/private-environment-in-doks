terraform {
  required_version = "1.5.7"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.30.0"
    }
  }

  backend "s3" {
    endpoint                    = "ams3.digitaloceanspaces.com"
    key                         = "testapp.tfstate"
    bucket                      = "testapp-terraform"
    region                      = "us-west-1"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_get_ec2_platforms      = true
    skip_metadata_api_check     = true
  }
}

variable "do_token" {}
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_domain" "default" {
  name = "yourdomain.com"
}

resource "digitalocean_vpc" "private" {
  name     = "private-network"
  region   = "ams3"
  ip_range = "192.168.99.0/24"
}

variable "root_public_ssh" {}
resource "digitalocean_ssh_key" "root_key" {
  name       = "root"
  public_key = var.root_public_ssh
}
