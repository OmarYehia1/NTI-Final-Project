variable "role_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "subjects" {
  type = list(string)
}

variable "policy_json" {
  type = string
}