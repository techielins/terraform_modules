//creates an aws iam role for enhanced monitoring
resource "aws_iam_role" "enhanced-monitoring-IAM-role-rds"{
    
    count               =   var.enable_enhanced_monitoring && var.monitoring_interval > 0 ? 1 : 0   
    name                =   lower("enhanced-monitoring-IAM-role-for-cluster-${var.cluster_identifier}")
    description         =   lower("Aurora PSQL enhanced monitoring IAM role for cluster - ${var.cluster_identifier}")
    assume_role_policy  = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "monitoring.rds.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole"
            ]
        }
    ]
})
     tags = merge({"ResourceName" = format("%s","enhanced monitoring IAM role for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Provides an IAM role inline policy.
    
resource "aws_iam_role_policy" "enhanced-monitoring-policy"{
    
    count       = var.enable_enhanced_monitoring && var.monitoring_interval > 0 ? 1 : 0   
    name        =   lower("Aurora-PSQL-enhanced-monitoring-policy-for-cluster-${var.cluster_identifier}")
    role        =   aws_iam_role.enhanced-monitoring-IAM-role-rds[0].name 
    policy      =   jsonencode({
        
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*"
            ]
        },
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*:log-stream:*"
            ]
        }
    ]
})
    depends_on = [aws_iam_role.enhanced-monitoring-IAM-role-rds]
}
  
//Creates a cloudwatch alarm using the metric CPU Utilization for the writer instance
  
resource "aws_cloudwatch_metric_alarm" "alarm_rds_CPU_writer" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0                                         
    alarm_name          = "Aurora PSQL CPU Utilization for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}"                    
    alarm_description   = "RDS CPU Utilization Alarm for Writer instance"
    comparison_operator = "GreaterThanOrEqualToThreshold" 
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "CPUUtilization"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Maximum" 
    threshold           = var.cloudwatch_alarm_writer_cpu_utilization_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Percent"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]

    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_0.*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_0.id
 
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL CPU Utilization for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}


//Creates a cloudwatch alarm using the metric CPU Utilization for the reader instance
  
resource "aws_cloudwatch_metric_alarm" "alarm_rds_CPU_reader" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL CPU Utilization for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}" 
    alarm_description   = "RDS CPU Utilization Alarm for Reader instance"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "CPUUtilization"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Maximum"
    threshold           = var.cloudwatch_alarm_reader_cpu_utilization_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Percent"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]

    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_n[0].*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_n[0].id  
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL CPU Utilization for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Free Local Storage for the writer instance
  
resource "aws_cloudwatch_metric_alarm" "free_local_storage_writer" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL FreeLocalStorage for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}"  
    alarm_description   = "This metric monitors Aurora Local Storage Utilization for writer instance class"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "FreeLocalStorage"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_writer_free_local_storage_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_0.*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_0.id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL FreeLocalStorage for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Free Local Storage for the reader instance
  
resource "aws_cloudwatch_metric_alarm" "free_local_storage_reader" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL FreeLocalStorage for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}" 
    alarm_description   = "This metric monitors Aurora Local Storage Utilization for Reader instance class"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "FreeLocalStorage"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_reader_free_local_storage_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_n[0].*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_n[0].id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL FreeLocalStorage for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Disk Queue Depth for the writer instance
  
resource "aws_cloudwatch_metric_alarm" "disk_queue_depth_writer" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL DiskQueueDepth for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}"
    alarm_description   = "Average database disk queue depth over last 1 minute too high, performance may suffer"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "DiskQueueDepth"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_writer_disk_queue_depth_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Count"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
   
    dimensions = {
        DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_0.*.id)
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL DiskQueueDepth for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Disk Queue Depth for the reader instance
  
resource "aws_cloudwatch_metric_alarm" "disk_queue_depth_reader" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL DiskQueueDepth for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}"
    alarm_description   = "Average database disk queue depth over last 1 minute too high, performance may suffer"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "DiskQueueDepth"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_reader_disk_queue_depth_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Count"
   
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_n[0].*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_n[0].id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL DiskQueueDepth for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Swap Usage for the writer instance
  
resource "aws_cloudwatch_metric_alarm" "swap_usage_writer" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL SwapUsage for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}" 
    alarm_description   = "Average database swap usage over last 1 minute too high, performance may suffer"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "SwapUsage"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_writer_swap_usage_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_0.*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_0.id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL SwapUsage for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Swap Usage for the reader instance
  
resource "aws_cloudwatch_metric_alarm" "swap_usage_reader" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL SwapUsage for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}"
    alarm_description   = "Average database swap usage over last 1 minute too high, performance may suffer"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "SwapUsage"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_reader_swap_usage_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"
    
    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]
    
    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_n[0].*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_n[0].id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL SwapUsage for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Freeable Memory for the writer instance
  
resource "aws_cloudwatch_metric_alarm" "freeable_memory_writer" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL FreeableMemory for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}" 
    alarm_description   = "Average database freeable memory over last 1 minute too low, performance may suffer - for writer instance"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "FreeableMemory"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_writer_freeable_memory_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"

    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]

    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_0.*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_0.id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL FreeableMemory for writer instance - ${aws_rds_cluster_instance.aurora_cluster_instance_0.identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates a cloudwatch alarm using the metric Freeable Memory for the reader instance
  
resource "aws_cloudwatch_metric_alarm" "freeable_memory_reader" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    alarm_name          = "Aurora PSQL FreeableMemory for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}" 
    alarm_description   = "Average database freeable memory over last 10 minutes too low, performance may suffer - for reader instance"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = var.cloudwatch_alarm_evaluation_period
    metric_name         = "FreeableMemory"
    namespace           = "AWS/RDS"
    period              = var.cloudwatch_alarm_period
    statistic           = "Average"
    threshold           = var.cloudwatch_alarm_reader_freeable_memory_threshold
    treat_missing_data  = "notBreaching"
    unit                = "Bytes"

    alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
    ok_actions          = [aws_sns_topic.sns_topic[0].arn]

    dimensions = {
        //DBInstanceIdentifier = join("", aws_rds_cluster_instance.aurora_cluster_instance_n[0].*.id)
        DBInstanceIdentifier = aws_rds_cluster_instance.aurora_cluster_instance_n[0].id
    }
    tags =  merge({"Alarm-Name" = format("%s","Aurora PSQL FreeableMemory for reader instance - ${aws_rds_cluster_instance.aurora_cluster_instance_n[0].identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"})
}

//Creates an SNS Topic for CloudWatch Alarm
  
resource "aws_sns_topic" "sns_topic" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    name                = "${var.cluster_identifier}-rds-events"
    tags                = merge({"ResourceName" = format("%s","Aurora PSQL SNS Topic for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"}) 
}

//Creates a resource for subscribing to SNS topics for CloudWatch Alarm
  
resource "aws_sns_topic_subscription" "updates_email" {
  
    count       = var.enable_cloudwatch_alarm ? 1 : 0
    topic_arn   = aws_sns_topic.sns_topic[0].arn
    protocol    = "email"
    endpoint    = var.endpoint
}

//Provides a DB event subscription resource for CloudWatch Alarm
  
resource "aws_db_event_subscription" "event_subscription" {
  
    count               = var.enable_cloudwatch_alarm ? 1 : 0
    name                = "${var.cluster_identifier}-rds-event-subscription"
    sns_topic           = aws_sns_topic.sns_topic[0].arn
    source_type         = "db-instance"
    source_ids          = [aws_rds_cluster_instance.aurora_cluster_instance_n[0].id, aws_rds_cluster_instance.aurora_cluster_instance_0.id]
    tags                = merge({"ResourceName" = format("%s","Aurora PSQL Event Subscription for cluster - ${var.cluster_identifier}")}, var.tags, {"Created At" = "${formatdate("YYYY/MM/DD hh:mm:ss", timestamp())} GMT"}) 
    event_categories    = [
        "creation",
        "deletion",
        "failover",
        "failure",
        "maintenance",
        "notification",
        "recovery",
    ]
}

