provider "aws" {
  region  = var.region
  profile = var.aws_profile_name
  version    = "~> 2.70"
}
