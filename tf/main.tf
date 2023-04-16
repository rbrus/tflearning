variable "environment" {
  type = object({
    name = string
  })
  nullable = false
}

variable "vaultConfig" {
  type = object({
    address = string
    token = string
  })
  nullable = false
}

variable "envs" {
  type = list
  nullable = false
}

variable "frontend" {
  type = object({
    imageName = string
    ports = object({
        internal = number
        external = number
  })
  })
  nullable = false
}

variable "account" {
  type = object({
    password = string
  })
  nullable = false
}

variable "gateway" {
  type = object({
    password = string
  })
  nullable = false
}

variable "payment" {
  type = object({
    password = string
  })
  nullable = false
}

terraform {
  required_version = ">= 1.0.7"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    vault = {
      version = "3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}

#resource "docker_container" "foo" {
#  image = docker_image.ubuntu.image_id
#  name  = "foo"
#}

provider "vault" {
  alias   = "secret_store"
  address = var.vaultConfig.address
  token   = var.vaultConfig.token
}

resource "vault_audit" "audit" {
  provider = vault.secret_store
  type     = "file"

  options = {
    file_path = "/vault/logs/audit"
  }
}

resource "vault_auth_backend" "userpass" {
  provider = vault.secret_store
  type     = "userpass"
}

resource "vault_generic_secret" "account_development" {
  provider = vault.secret_store
  path     = "secret/${var.environment.name}/account"

  data_json = <<EOT
{
  "db_user":   "account",
  "db_password": ${var.account.password}
}
EOT
}

resource "vault_policy" "account_development" {
  provider = vault.secret_store
  name     = "account-${var.environment.name}"

  policy = <<EOT

path "secret/data/${var.environment.name}/account" {
    capabilities = ["list", "read"]
}

EOT
}

resource "vault_generic_endpoint" "account_development" {
  provider             = vault.secret_store
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/account-${var.environment.name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["account-${var.environment.name}"],
  "password": "123-account-${var.environment.name}"
}
EOT
}

resource "vault_generic_secret" "gateway_development" {
  provider = vault.secret_store
  path     = "secret/${var.environment.name}/gateway"

  data_json = <<EOT
{
  "db_user":   "gateway",
  "db_password": ${var.gateway.password}
}
EOT
}

resource "vault_policy" "gateway_development" {
  provider = vault.secret_store
  name     = "gateway-${var.environment.name}"

  policy = <<EOT

path "secret/data/${var.environment.name}/gateway" {
    capabilities = ["list", "read"]
}

EOT
}

resource "vault_generic_endpoint" "gateway_development" {
  provider             = vault.secret_store
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/gateway-${var.environment.name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["gateway-${var.environment.name}"],
  "password": "123-gateway-${var.environment.name}"
}
EOT
}
resource "vault_generic_secret" "payment_development" {
  provider = vault.secret_store
  path     = "secret/${var.environment.name}/payment"

  data_json = <<EOT
{
  "db_user":   "payment",
  "db_password": ${var.payment.password}
}
EOT
}

resource "vault_policy" "payment_development" {
  provider = vault.secret_store
  name     = "payment-${var.environment.name}"

  policy = <<EOT

path "secret/data/${var.environment.name}/payment" {
    capabilities = ["list", "read"]
}

EOT
}

resource "vault_generic_endpoint" "payment_development" {
  provider             = vault.secret_store
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/payment-${var.environment.name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["payment-${var.environment.name}"],
  "password": "123-payment-${var.environment.name}"
}
EOT
}


resource "docker_container" "account_development" {
  image = "form3tech-oss/platformtest-account"
  name  = "account"
  env = var.envs

  networks_advanced {
    name = "vagrant"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "docker_container" "gateway_development" {
  image = "form3tech-oss/platformtest-gateway"
  name  = "gateway"
  env = var.envs

  networks_advanced {
    name = "vagrant"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "docker_container" "payment_development" {
  image = "form3tech-oss/platformtest-payment"
  name  = "payment"
  env = var.envs

  networks_advanced {
    name = "vagrant"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "docker_container" "frontend_development" {
  image = var.frontend.imageName
  name  = "frontend"

  ports {
    internal = var.frontend.ports.internal
    external = var.frontend.ports.external
  }

  networks_advanced {
    name = "vagrant"
  }

  lifecycle {
    ignore_changes = all
  }
}
