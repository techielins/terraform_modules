//Creates a private subnet group

resource "aws_db_subnet_group" "private_p" {
  
    name        =       lower("Aurora PSQL DB Subnet Group for cluster - ${var.cluster_identifier}")
    description =       lower("Aurora PSQL DB subnet group for cluster - ${var.cluster_identifier}")
    subnet_ids  =       var.private_subnet_ids_p
    tags        =       merge({"ResourceName" = format("%s","Aurora PSQL DB Subnet Group for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}


//Creates a security group

resource "aws_security_group" "aurora_security_group"{

    count       =   var.create_security_group ? 1 : 0
    name        =       lower("Aurora PSQL DB Subnet Group for cluster - ${var.cluster_identifier}")
    description =       lower("Aurora PSQL subnet-group for ${var.cluster_identifier}")
    vpc_id      =   var.vpc_id
    tags        =   merge({"ResourceName" = format("%s","Aurora PSQL DB Subnet Group for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates security group rule - ingress

resource "aws_security_group_rule" "cidr_ingress"{
    
    count               =   var.create_security_group ? 1 : 0
    description         =   lower("Aurora PSQL inbound traffic for cluster - ${var.cluster_identifier}")
    type                =   "ingress"
    from_port           =   var.port
    to_port             =   var.port
    protocol            =   "tcp"
    security_group_id   =   aws_security_group.aurora_security_group[0].id
    cidr_blocks         =   var.security_group_ingress_cidr_block
}

//Creates security group rule - egress

resource "aws_security_group_rule" "cidr_egress"{

    count               =   var.create_security_group ? 1 : 0
    description         =   lower("Aurora PSQL allow all outbound traffic for cluster - ${var.cluster_identifier}")
    type                =   "egress"
    from_port           =   "0"
    to_port             =   "0"
    protocol            =   "all"
    security_group_id   =   aws_security_group.aurora_security_group[0].id
    cidr_blocks         =   ["0.0.0.0/0"]
}
