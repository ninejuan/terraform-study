provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Project = "terraform-study"
      Environment = "development"
    }
  }
}