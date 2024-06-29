variable "region" {
  type = string
  description = "AWS region that will be used"
  default = "us-west-2"
}

variable "bucket_name" {
    type = string
    description = "unique name of the bucket"
    default = "defensepoint-pedro-28-06-2024"
}

variable "environment" {
    type = string  
    description = "name of the environment that app/infra will be deployed to"
    default = "devel"
}

variable "tags_list" {
    type = map(string)
    description = "map of tags"
    default = {
      "project" = "defensepoint-assessment"
      "owner" = "pedrodevops@gmail.com"
    }
}