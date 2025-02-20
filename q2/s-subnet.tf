###################################
# For common countrycode subnets required aws infra
####################################
data "aws_subnets" "infra" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name = "tag:Name"
    values = [
      "asiayo-infra*"
    ]
  }
  tags = {
    "user:creator" = "terraform"
  }
}

data "aws_subnet" "infra" {
  count = length(data.aws_subnets.infra.ids)
  filter {
    name = "tag:Name"
    values = [
      "asiayo-infra*"
    ]

  }
}