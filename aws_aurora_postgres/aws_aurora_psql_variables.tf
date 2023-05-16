variable "region"{
    description = "Name of the region for the resource to be provisioned"
    type        = string
    default     = null
}

variable "tags"{
    description = "A map of tags to add to all resources" 
    type        = map(string)
    default     = {
        Name = "Aurora-DB"
    }
}

##########################################################
#CLOUDWATCH ALARM
##########################################################

variable "enable_cloudwatch_alarm"{
    description = "Specifies whether to enable cloud watch alarm."
    type        = bool
    default     = false
}

variable "cloudwatch_alarm_evaluation_period"{
    description = "The number of periods over which data is compared to the specified threshold."
    type        = number
    default     = 2
}

variable "cloudwatch_alarm_period"{
    description = "The period in seconds over which the specified statistic is applied."
    type        = number
    default     = 60
}

variable "cloudwatch_alarm_writer_cpu_utilization_threshold"{
    description = "The maximum percentage of CPU utilization for writer instance ."
    type        = number
    default     = 80
}

variable "cloudwatch_alarm_reader_cpu_utilization_threshold"{
    description = "The maximum percentage of CPU utilization for reader instance."
    type        = number
    default     = 80
}

variable "cloudwatch_alarm_writer_free_local_storage_threshold"{
    description = "The amount of local storage available for writer instance in Bytes."
    type        = number
    default     = 5368709120
}

variable "cloudwatch_alarm_reader_free_local_storage_threshold"{
    description = "The amount of local storage available for reader instance in Bytes."
    type        = number
    default     = 5368709120
}

variable "cloudwatch_alarm_writer_disk_queue_depth_threshold"{
    description = "The maximum number of outstanding IOs (read/write requests) waiting to access the disk for the writer instance."
    type        = number
    default     = 50
}

variable "cloudwatch_alarm_reader_disk_queue_depth_threshold"{
    description = "The maximum number of outstanding IOs (read/write requests) waiting to access the disk for the reader instance."
    type        = number
    default     = 50
}

variable "cloudwatch_alarm_writer_swap_usage_threshold"{
    description = "The maximum amount of swap space used on the DB instance in Byte for the writer instance."
    type        = number
    default     = 256000000
}

variable "cloudwatch_alarm_reader_swap_usage_threshold"{
    description = "The maximum amount of swap space used on the DB instance in Byte for the reader instance."
    type        = number
    default     = 256000000
}

variable "cloudwatch_alarm_writer_freeable_memory_threshold"{
    description = "The minimum amount of available random access memory in Byte for the writer instance."
    type        = number
    default     = 64000000
}

variable "cloudwatch_alarm_reader_freeable_memory_threshold"{
    description = "The minimum amount of available random access memory in Byte for the reader instance."
    type        = number
    default     = 64000000
}

variable "endpoint"{
    description = "Endpoint to which cloudwatch alarm notifications are send to."
    type        = string
    default     = null
}

##########################################################
#RANDOM PASSWORD 
##########################################################

variable "random_password_length"{
    description = "Length of random password to be generated" 
    type        = number
    default     = "10"
}

variable "special_character"{
    description = "Determine whether to include special characters in the random password generation"
    type        = bool
    default     = true
}

############################################################
#DB SUBNET group
############################################################

variable "private_subnet_ids" {
    description = "A list of private subnet IDs in VPC region"
    type        = list(string)
    default     = null
}

#############################################################
#ENHANCED MONITORING 
#############################################################

variable "monitoring_interval"{
    description = "Enhanced Monitoring interval in seconds - valid values are 0, 1, 5, 10, 15, 30, 60."
                  //To enable enhanced monitoring, monitoring_interval must be a non-zero value and check_enhanced_monitoring must be set to true//
                  //To disable enhanced monitoring, 'monitoring_interval' must be set to 0 and 'check_enhanced_monitoring' must be false//
    type        = number
    default     = "10"
    validation {
    condition  = contains([0,1,5,10,15,30,60], var.monitoring_interval)
   error_message = "Please enter a valid value. valid values are 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "enable_enhanced_monitoring"{
    description = "Determines whether enhanced monitoring should be enabled or not - valid values are 'true' and 'false'."
                  //To enable enhanced monitoring, 'check_enhanced_monitoring' must be set to true and 'monitoring_interval' must be a non-zero value//
                  //To disable enhanced monitoring, 'check_enhanced_monitoring' must be false and 'monitoring_interval' must be set to 0//
    type        = bool
    default     = true
}

##############################################################
#READ REPLICA 
##############################################################

variable "replica_scale_enabled" {
    description = "Whether to enable autoscaling for RDS Aurora read replicas"
    type        = string
    default     = true
}
variable "replica_count" {
    description = "If 'replica_scale_enable' is 'true', the value of this variable is used to create read replica, else only writer instance will be created."
    type        = string
    default     = "1"
}

##############################################################
#SECURITY GROUP
##############################################################

variable "create_security_group"{
    description = "Specifies whether a security group should be created or not"
                    //If false, then existing security group is used for creating the DB cluster
    type        = bool
    default     = null
}

variable "security_group_ingress_cidr_block"{
    description = "CIDR block for ingress rule"
    type        = list(string)
    default     = ["0.0.0.0/0"]
}


##############################################################
#STORAGE ENCRYPTION 
##############################################################

variable "storage_encrypted"{
    description = "Specifies whether the DB cluster is encrypted"
                   //The default is 'false' for 'provisioned' 'engine_mode' and 'true' for 'serverless' 'engine_mode'.
                   //Aurora RDS instance can be encrypted when we create it, not after the instance is created.
    type        = bool
    default     = true
}

variable "create_cms_key"{
    description = "Specifies whether CMS Key should be created or not"
    type        = bool
    default     = false
}

variable "kms_key_deletion_window_in_days"{
    description = "The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key."
                    //The value must be between 7 and 30.
    type        = number
    default     = "10"
}

################################################################
#DB CLUSTER PARAMETER group
################################################################

variable "family"{
    description =  "The family of the DB parameter group"
    type        = string
    default     = null
}

variable "db_cluster_parameter_group_parameters"{
    description = "A list of DB parameters to apply."
    type        = list(map(string))
    default     = [{
                        name    =   "rds.force_ssl"
                        value   =   0
    }]
}
################################################################
#CLUSTER 
################################################################


variable "allow_major_version_upgrade"{
    description = "Determines whether to allow major engine version upgrades when changing engine versions"
    type        = bool
    default     = false
}

variable "apply_immediately"{
    description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
    type        = bool
    default     = false
}

variable "availability_zones"{
    description = "List of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created"
                   //RDS automatically assigns 3 AZs if less than 3 AZs are configured
    type        = list(string)
    default     = null
}

variable "backup_retention_period"{
    description = "The number of days to retain backups for"
    type        = number
    default     = "5"
}

variable "cluster_identifier"{
    description = "The name of the DB cluster"
    type        = string 
    default     = null
}

variable "database_name"{
    description = "The name of the database to be created"
    type        = string 
    default     = "psqlaurora"
}

variable "deletion_protection"{
    description = "Specifies whether the DB instance should have deletion protection enabled"
                   //The database can't be deleted when this value is set to 'true'
    type        = bool
    default     = false
}

variable "engine"{
    description = "The name of the database engine to be used for the DB cluster."
    type        = string
    default     = null
    validation {
    condition  = contains(["aurora-postgresql"], var.engine)
   error_message = "The engine should be 'aurora-postgresql' only. "
  }
}

variable "engine_mode"{
    description = "The database engine mode."
    type        = string
    default     = "provisioned"
    validation {
    condition  = contains(["provisioned"], var.engine_mode)
   error_message = "The engine_mode should be 'provisioned' only. "
  }
}

variable "engine_version"{
    description = "The database engine version"
    type        = string
    default     = null
}

variable "iam_database_authentication_enabled"{
    description = "Determines whether to enable IAM database authentication for the RDS Cluster"
    type        = bool
    default     = true
}

variable "master_username"{
    description = "Username for the master DB user"
    type        = string
    default     = "psqladmin"
}

variable "port"{
    description = "The port on which to accept connections"
    type        = number
    default     = 5432
}
variable "preferred_backup_window" {
    description = "The daily time range during which automated backups are created."
    type = string
    default = "09:00-10:00"
}
variable "preferred_maintenance_window" {
    description = "The weekly time range during which system maintenance can occur, in (UTC)"
    type = string
    default = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot"{
    description = "Determines whether a final snapshot has to be created before the cluster is deleted. If 'true', no snapshot is created"
    type        = bool
    default     = true
}

variable "security_group_id" {
    description = "The security group to be connected"
    type        = list(string) 
    default     = null
}

################################################################
#INSTANCE
################################################################

variable "auto_minor_version_upgrade"{
    description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
    type        = bool
    default     = false
}

variable "instance_class"{
    description = "Instance type to use at replica instance"
    type        = string 
    default     = null
}

variable "publicly_accessible"{
    description = "Determines whether the DB should have a public IP address"
                    //if set to Yes, the database will have a publicly accessible endpoint and may be exposed to the internet
    type        = bool
    default     = false
}

variable "performance_insights_enabled"{
    description = "Determines whether Performance Insights is enabled or not"
                    //helps to quickly assess the load on database, and determine when and where to take action.
                    //The specified VPC should have DNS resolution and  DNS hostnames enabled.
                    //Instance classes - db.t3.small, db.t3.medium, db.t3.large - do not support performance insight.
    type        = bool
    default     = true
}

variable "promotion_tier"{
    description = "Specifies the order in which Aurora Replica is promoted to the primary instance in a cluster"
                    //Priorities range from 0 for the first priority to 15 for the last priority.
                    //If the primary instance fails, AWS RDS promotes the Aurora Replica with the better priority to the new primary instance.
    type        = number
    default     = "0"
}

variable "serverlessv2_scaling_configuration" {
    description = "Map of nested attributes with serverless v2 scaling properties. Only valid when `engine_mode` is set to `provisioned`"
                   //The minimum capacity must be lesser than or equal to the maximum capacity. 
                   //Valid capacity values are in a range of 0.5 up to 128 in steps of 0.5.
    type        = any
    default     = {
                    max_capacity = 10
                    min_capacity = 2
 }
}

variable "enable_kms_key_rotation" {
    description = "Specifies whether key rotation is enabled"
    type        = bool
    default     = true
}


################################################################
#Autoscaling
################################################################
variable "replica_scale_max" {
  description = "Maximum number of read replicas to allow scaling for"
  type        = number
  default     = 2
  validation {
    condition  = var.replica_scale_max < 16 && var.replica_scale_max > 1
    error_message = "replica_scale_max value should be within 2 to 15"
  }
}
variable "replica_scale_min" {
  description = "Minimum number of read replicas to allow scaling for"
  type        = number
  default     = 1
}

variable "replica_scale_cpu" {
  description = "CPU usage to trigger autoscaling at"
  type        = number
  default     = 70
}

variable "replica_scale_connections" {
  description = "Average number of connections to trigger autoscaling at. Default value is 70% of db.r4.large's default max_connections"
  type        = number
  default     = 700
}

variable "replica_scale_in_cooldown" {
  description = "Cooldown in seconds before allowing further scaling operations after a scale in"
  type        = number
  default     = 300
}

variable "replica_scale_out_cooldown" {
  description = "Cooldown in seconds before allowing further scaling operations after a scale out"
  type        = number
  default     = 300
}
variable "autoscaling_predefined_metric_type" {
  description = "The metric type to scale on. Valid values are RDSReaderAverageCPUUtilization and RDSReaderAverageDatabaseConnections."
  default     = "RDSReaderAverageCPUUtilization"
}

