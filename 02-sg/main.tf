module "sg_db" {
    source = "../../terraform-aws-securitygroup"
    # source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "database security group"
    sg_name = "db"
    common_tags = var.common_tags

}

module "ingress" {
    source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG for Ingress controller"
    sg_name = "ingress"
    common_tags = var.common_tags
}

module "cluster" {
    source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG for EKS Control plane "
    sg_name = "eks-control-plane"
    common_tags = var.common_tags
}

module "node" {
    source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG for EKS node"
    sg_name = "eks-node"
    common_tags = var.common_tags
}


module "sg_bastion" {
    source = "../../terraform-aws-securitygroup"
    # source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "security group for bastion instances"
    sg_name = "bastion"
    common_tags = var.common_tags

}

module "vpn" {
    source = "../../terraform-aws-securitygroup"
    # source = "git::https://github.com/kaminenileela/terraform-aws-securitygroup.git"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG for VPN Instances"
    sg_name = "vpn"
    common_tags = var.common_tags
    ingress_rules = var.vpn_sg_rules
        
}

resource "aws_security_group_rule" "db_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.sg_bastion.sg_id  #source is where you are getting traffic from
  security_group_id = module.sg_db.sg_id
}

resource "aws_security_group_rule" "db_vpn" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id  #source is where you are getting traffic from
  security_group_id = module.sg_db.sg_id
}

resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.sg_bastion.sg_id
}

resource "aws_security_group_rule" "cluster_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = module.node.sg_id
  security_group_id = module.cluster.sg_id
}

resource "aws_security_group_rule" "node_cluster" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = module.cluster.sg_id
  security_group_id = module.node.sg_id
}

resource "aws_security_group_rule" "node_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = module.ingress.sg_id
  security_group_id = module.node.sg_id
}

resource "aws_security_group_rule" "db_node" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.node.sg_id
  security_group_id = module.db.sg_id
}

resource "aws_security_group_rule" "ingress_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}