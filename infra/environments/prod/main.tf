terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  backend "s3" {
    bucket = "taskboard-tf-state-679965617139"
    key    = "prod/terraform.tfstate"
    region = "eu-west-1"
  }
}



provider "aws" {
  region = "eu-west-1"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Allow the load balancer to reach the backend pods on port 8000
resource "aws_security_group_rule" "alb_to_pods" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.alb.security_group_id
  description              = "ALB to backend pods"
}

# The secret that proves a request came from our CloudFront
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}
# The database password: random, never written by hand
resource "random_password" "db" {
  length  = 24
  special = false
}

# Where it is stored in AWS
resource "aws_secretsmanager_secret" "db" {
  name                    = "taskboard/prod/db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
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

module "staticsite" {
  source        = "../../bootstrap/modules/staticsite"
  bucket_name   = "taskboard-frontend-679965617139"
  alb_dns_name  = module.alb.alb_dns_name
  origin_secret = random_password.origin_verify.result
}

module "ecr" {
  source          = "../../bootstrap/modules/ecr"
  repository_name = "taskboard-backend"
}

module "alb" {
  source        = "../../bootstrap/modules/alb"
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.public_subnet_ids
  origin_secret = random_password.origin_verify.result
}

module "platform" {
  source       = "../../bootstrap/modules/platform"
  cluster_name = module.eks.cluster_name
  region       = "eu-west-1"
  vpc_id       = module.network.vpc_id
}

# The GitHub trust relationship made by bootstrap
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# The role used by the backend, frontend and release workflows
module "github_deploy_role" {
  source            = "../../bootstrap/modules/githuboidc-role"
  role_name         = "taskboard-prod-github-deploy"
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  subjects = [
    "repo:OmarYehia1/NTI-Final-Project:ref:refs/heads/main",
    "repo:OmarYehia1/NTI-Final-Project:ref:refs/tags/*",
    "repo:OmarYehia1/NTI-Final-Project:environment:production",
  ]

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Log in to ECR (this one cannot be limited to one repo)
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # Push and promote images, only in our repo
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = "arn:aws:ecr:eu-west-1:679965617139:repository/taskboard-backend"
      },
      {
        # Upload the website, only in our bucket
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.staticsite.bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.staticsite.bucket_arn
      },
      {
        # Clear the cache, only on our distribution
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = module.staticsite.distribution_arn
      },
    ]
  })
}



output "github_deploy_role_arn" {
  value = module.github_deploy_role.role_arn
}

output "ecr_repository_url" {
  value = "679965617139.dkr.ecr.eu-west-1.amazonaws.com/taskboard-backend"
}

output "frontend_bucket" {
  value = module.staticsite.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.staticsite.distribution_id
}

output "app_url" {
  value = "https://${module.staticsite.domain_name}"
}

output "backend_target_group_arn" {
  value = module.alb.target_group_arn
}