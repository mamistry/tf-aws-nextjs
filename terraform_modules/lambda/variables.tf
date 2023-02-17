variable "output_path" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "function_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = any
  default = null
}

variable "s3_bucket_id" {
  type = any
  default = null
}

variable "s3_object_key" {
  type = string
}

variable "role_arn" {
  type = any
  default = null
}

variable "name" {
  type = string
}

variable "sqs_default_queue_arn" {
  type = string
}
