variable "cluster_name" {
  type    = string
  default = "taskboard-prod"
}

variable "subnet_ids" {
  type    = list(string)
}

variable "vpc_id" {
  type    = string
}