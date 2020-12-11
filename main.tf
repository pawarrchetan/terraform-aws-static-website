provider "aws" {
  profile = "development"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "xxxxxxxx-terraform-backend"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "module-frontend-static-website" {
  source                 = "./modules/static-website/"
  domain_name            = var.domain_name
  alternate_domain_names = var.alternate_domain_names
  zone_id                = var.zone_id
}