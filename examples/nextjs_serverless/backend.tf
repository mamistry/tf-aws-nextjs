terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "<bucket_name>" //eg. gsp.aws.nextjs.terraform
    key = "<env>/state.tfstate" //eg. dev/state.tfstate
    encrypt = true    #AES-256 encryption
  }
}