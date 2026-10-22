terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "taskboard-tf-state-679965617139"
    key    = "prod/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "network" {
  source      = "../../bootstrap/modules/network"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"
}

module "eks" {
  source       = "../../bootstrap/modules/eks"
  cluster_name = "taskboard-prod"
  vpc_id       = module.network.vpc_id
  subnet_ids   = module.network.private_subnet_ids
}

module "ecr" {
  source          = "../../bootstrap/modules/ecr"
  repository_name = "taskboard-backend"
}

module "alb" {
  source     = "../../bootstrap/modules/alb"
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids
}

import {
  to = module.ecr.aws_ecr_repository.backend
  id = "taskboard-backend"
}