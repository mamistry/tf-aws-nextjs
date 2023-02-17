terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "beatsnextjs.terraform"
    key = "state.tfstate"
    encrypt = true    #AES-256 encryption
  }
}