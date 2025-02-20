
variable "vpc_id" {
  type    = string
  default = "vpc-xxxxx"
}

locals {
  vpc_id = var.vpc_id
}