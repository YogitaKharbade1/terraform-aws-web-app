module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  prefix             = var.prefix
}

module "ec2" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.subnet_ids
  prefix        = var.prefix
  instance_type = var.instance_type
  ami_id        = var.ami_id
  key_name      = var.key_name
}
