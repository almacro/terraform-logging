# backend_override.tf
terraform {
  backend "local" {
    path = "./.local-state"
  }
}
