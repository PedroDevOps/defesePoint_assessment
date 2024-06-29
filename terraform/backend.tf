terraform {

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.50"
    }
  }

  backend "s3" {
    bucket = "defensepoint-tfstate-pedro-28-06-2024"
    key    = "terraform.tfstate"
    region = "us-west-2"  
  }
}
