terraform {
  # Minimum versions: fail fast if the environment is wrong.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # ~> means: any 6.x, never 7.0 (pessimistic constraint)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource this provider creates gets these tags automatically.
  # One block replaces remembering to tag 60+ resources by hand.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}