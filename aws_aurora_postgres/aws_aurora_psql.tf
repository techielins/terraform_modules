# Retrieve information about the available AWS availability zones in the current region
# This is done using the "aws_availability_zones" data source provided by the AWS provider for Terraform
//availability zone
data "aws_availability_zones" "azs" {
  # Specify the state of the availability zones to retrieve
  # In this case, we only want to retrieve availability zones that are "available"
  state = "available"
}

# Retrieve information about the AWS account and identity associated with the current credentials
# This is done using the "aws_caller_identity" data source provided by the AWS provider for Terraform
// data source to get the access to the effective Account ID
data "aws_caller_identity" "current" {
  # No arguments are needed for this data source, as it automatically uses the current credentials
  # The "aws_caller_identity.current" object can be used to access information about the current identity
  # such as the AWS account ID, ARN, and user or role name
}

locals {
  
  # Define a new local variable called "az_names"
  # Retrieve the names of the first two availability zones in the current region
  # This is done using the "slice" function to extract the first two names from the list
  az_names = slice(data.aws_availability_zones.azs.names,0,2)
  
  # Define a new local variable called "account_id"
  # Retrieve the AWS account ID of the currently authenticated user or role
  # This is done using the "data.aws_caller_identity" data source
  account_id = data.aws_caller_identity.current.account_id
}


# Create an AWS Aurora RDS cluster with the specified configuration

resource "aws_rds_cluster" "aurora_cluster" {
    
    allow_major_version_upgrade         =   var.allow_major_version_upgrade
    apply_immediately                   =   var.apply_immediately
    availability_zones                  =   local.az_names
    backup_retention_period             =   var.backup_retention_period
    cluster_identifier                  =   var.cluster_identifier
    database_name                       =   var.database_name
    db_cluster_parameter_group_name     =   aws_rds_cluster_parameter_group.aurora_cluster_parameter_group.name
    db_subnet_group_name                =   aws_db_subnet_group.private_p.name
    deletion_protection                 =   var.deletion_protection
    engine                              =   var.engine
    engine_mode                         =   var.engine_mode
    engine_version                      =   var.engine_version
    iam_database_authentication_enabled =   var.iam_database_authentication_enabled
    kms_key_id                          =   var.create_cms_key ? aws_kms_key.kms_aurora_cluster[0].arn : null
    master_username                     =   var.master_username
    master_password                     =   random_password.master_password.result 
    port                                =   var.port
    preferred_backup_window             =   var.preferred_backup_window
    preferred_maintenance_window        =   var.preferred_maintenance_window
    skip_final_snapshot                 =   var.skip_final_snapshot
    storage_encrypted                   =   var.storage_encrypted
    vpc_security_group_ids              =   var.create_security_group ? [aws_security_group.aurora_security_group[0].id] : var.security_group_id
    
    # Set up scaling configuration for the serverless engine mode
    dynamic "serverlessv2_scaling_configuration" {
    for_each = length(var.serverlessv2_scaling_configuration) > 0 && var.engine_mode == "provisioned" ? [var.serverlessv2_scaling_configuration] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
        }
     }  
    
    # Set up tags for the cluster, including a resource name and creation timestamp
    tags        = merge({"ResourceName" = format("%s",var.cluster_identifier)}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
    depends_on  = [aws_rds_cluster_parameter_group.aurora_cluster_parameter_group,aws_db_parameter_group.aurora_db_parameter_group]
    
    # Define preconditions for the lifecycle of the AWS RDS Aurora cluster resource
    lifecycle {
    # Check that replica_scale_min is not greater than replica_scale_max if replica scaling is enabled  
    precondition {
      condition     = var.replica_scale_enabled ? (var.replica_scale_min <= var.replica_scale_max) : true
      error_message = "replica_scale_min should not be greater than replica_scale_max"
    }
    # Check that a KMS key is specified only if storage encryption is enabled  
    precondition {
      condition = ((var.create_cms_key==true) ? (var.storage_encrypted== true) : true)
      error_message = "KMS key cannot be specified for unencrypted cluster. When create_cms_key is set to true, storage_encrypted must also be true."
    }
    }
}

//creates writer instance

resource "aws_rds_cluster_instance" "aurora_cluster_instance_0" {
    
    apply_immediately               =   var.apply_immediately
    auto_minor_version_upgrade      =   var.auto_minor_version_upgrade
    cluster_identifier              =   var.cluster_identifier
    db_parameter_group_name         =   aws_db_parameter_group.aurora_db_parameter_group.name
    db_subnet_group_name            =   aws_db_subnet_group.private_p.name
    engine                          =   aws_rds_cluster.aurora_cluster.engine
    engine_version                  =   aws_rds_cluster.aurora_cluster.engine_version
    identifier                      =   lower("${var.cluster_identifier}-instance-0")
    instance_class                  =   var.instance_class
    monitoring_interval             =   var.monitoring_interval   
    monitoring_role_arn             =   var.enable_enhanced_monitoring == true ? aws_iam_role.enhanced-monitoring-IAM-role-rds[0].arn : null
    promotion_tier                  =   var.promotion_tier
    publicly_accessible             =   var.publicly_accessible
    performance_insights_enabled    =   var.performance_insights_enabled
    
    tags                            =   merge({"ResourceName" = format("%s","${var.cluster_identifier}-instance-0")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
    depends_on                      =   [aws_rds_cluster.aurora_cluster]
    lifecycle {
    #Precondition to check if enhanced monitoring is enabled, then monitoring interval should be set to 1, 5, 10, 15, 30 or 60  
    precondition {
      condition     = ((var.enable_enhanced_monitoring == true ) ? (var.monitoring_interval > 0 ) : true)
      error_message = "If enable_enhanced_monitoring is set to true, then monitoring_interval should be either 1, 5, 10, 15, 30 or 60"
        }
    #Precondition to check if enhanced monitoring is disabled, then monitoring interval should be set to 0  
    precondition {
      condition     = ((var.enable_enhanced_monitoring == false ) ? (var.monitoring_interval == 0 ) : true)
      error_message = "If enable_enhanced_monitoring is set to false, then monitoring_interval should be set to 0."
        }
    #Precondition to check if instance_class is db.serverless, then engine_version should be between 13.6-13.8 , 14.3-14.7 and 15.2  
    precondition {
      condition     = var.instance_class == "db.serverless" ? contains(["13.6","13.7","13.8","14.3","14.4","14.5","14.6","14.7","15.2"], var.engine_version) : true
      error_message = "If instance_class is set to db.serverless, then engine_version should be between 13.6-13.8 , 14.3-14.7 and 15.2 "
        }
    }
}
  
//creates read replicas

resource "aws_rds_cluster_instance" "aurora_cluster_instance_n" {
     
    count  = var.replica_scale_enabled ? var.replica_scale_min : var.replica_count     
    apply_immediately               =   var.apply_immediately
    auto_minor_version_upgrade      =   var.auto_minor_version_upgrade
    cluster_identifier              =   var.cluster_identifier
    db_parameter_group_name         =   aws_db_parameter_group.aurora_db_parameter_group.name
    db_subnet_group_name            =   aws_db_subnet_group.private_p.name
    engine                          =   var.engine
    engine_version                  =   var.engine_version
    identifier                      =   lower("${var.cluster_identifier}-instance-${count.index + 1}")
    instance_class                  =   var.instance_class
    monitoring_interval             =   var.monitoring_interval   
    monitoring_role_arn             =   var.enable_enhanced_monitoring == true ? aws_iam_role.enhanced-monitoring-IAM-role-rds[0].arn : null
    performance_insights_enabled    =   var.performance_insights_enabled
    promotion_tier                  =   count.index+1
    publicly_accessible             =   var.publicly_accessible
    
    tags                            =   merge({"ResourceName" = format("%s","${var.cluster_identifier}-instance-${count.index + 1}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
    depends_on                      = [aws_rds_cluster_instance.aurora_cluster_instance_0]
}

resource "aws_appautoscaling_target" "read_replica_count" {
  
  count = var.replica_scale_enabled ? 1 : 0
  max_capacity       = var.replica_scale_max
  min_capacity       = var.replica_scale_min
  resource_id        = "cluster:${element(concat(aws_rds_cluster.aurora_cluster.*.cluster_identifier, [""]), 0)}"
 scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
  }

resource "aws_appautoscaling_policy" "autoscaling_read_replica_count" {
  
  count = var.replica_scale_enabled ? 1 : 0
  name               = "target-metric"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "cluster:${element(concat(aws_rds_cluster.aurora_cluster.*.cluster_identifier, [""]), 0)}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_predefined_metric_type
    }

    scale_in_cooldown  = var.replica_scale_in_cooldown
    scale_out_cooldown = var.replica_scale_out_cooldown
    target_value       = var.autoscaling_predefined_metric_type == "RDSReaderAverageCPUUtilization" ? var.replica_scale_cpu : var.replica_scale_connections
  }
  depends_on = [aws_appautoscaling_target.read_replica_count]
}

//generates random password- sensitive in nature

resource "random_password" "master_password" {
    
    length              =   var.random_password_length
    special             =   var.special_character
    override_special    =   "!#%&*()-_=+[]{}<>:?"
}

//creates a kms key for aurora cluster
  
resource "aws_kms_key" "kms_aurora_cluster"{
    
    count                   =   var.create_cms_key ? 1 : 0   
    description             =   lower("Aurora PSQL CMS key for Cluster - ${var.cluster_identifier}")
    key_usage               =   "ENCRYPT_DECRYPT"
    enable_key_rotation     =   var.enable_kms_key_rotation
    deletion_window_in_days =   var.kms_key_deletion_window_in_days
    tags                    =   merge({"ResourceName" = format("%s","Aurora PSQL CMS key for Cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"}) 
    policy                  =   jsonencode({
    "Id": "key-consolepolicy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
    })
}

//Provides an RDS DB parameter group resource
  
resource "aws_db_parameter_group" "aurora_db_parameter_group"{
    
    name            =   lower("Aurora-PSQL-Parameter-Group-for-instance-${var.cluster_identifier}")
    family          =   var.family
    description     =   lower("Aurora PSQL Parameter Group for ${var.cluster_identifier}")
    tags            =   merge({"ResourceName" = format("%s","Aurora PSQL Parameter Group for instance - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
    lifecycle {
        create_before_destroy = true
    }
}

//Provides an RDS DB cluster parameter group resource
  
resource "aws_rds_cluster_parameter_group" "aurora_cluster_parameter_group" {
    
    name            =   lower("Aurora-PSQL-Cluster-Parameter-Group-for-cluster-${var.cluster_identifier}")
    family          =   var.family
    description     =   lower("Aurora PSQL Cluster Parameter Group for ${var.cluster_identifier}")
    tags            =   merge({"ResourceName" = format("%s","Aurora PSQL Cluster Parameter Group for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
    
    dynamic "parameter" {
        for_each = var.db_cluster_parameter_group_parameters

        content{
            name            =   parameter.value.name
            value           =   parameter.value.value
            apply_method    =   try(parameter.value.apply_method, "immediate")
        }
        
    }
    lifecycle {
        create_before_destroy = true
    } 
}
  
 

