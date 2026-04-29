data "aws_availability_zones" "available" {}

module "vpc" {
  source         = "./modules/vpc"
  vpc_name       = var.project_name
  vpc_cidr       = var.vpc_cidr
  public_subnets = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  azs            = data.aws_availability_zones.available.names
}

module "part1" {
  source        = "./part1"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  instance_type = var.instance_type
}

module "part2" {
  source        = "./part2"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  instance_type = var.instance_type
}

module "part3" {
  source            = "./part3"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}
