terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "gsp.aws.nextjs.terraform"
    key = "state.tfstate"
    encrypt = true    #AES-256 encryption
  }
}