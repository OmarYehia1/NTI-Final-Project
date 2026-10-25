variable "bucket_name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "origin_secret" {
  type      = string
  sensitive = true
}