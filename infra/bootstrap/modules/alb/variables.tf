variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "origin_secret" {
  type      = string
  sensitive = true
}