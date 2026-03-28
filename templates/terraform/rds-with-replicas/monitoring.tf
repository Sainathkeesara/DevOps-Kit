################################################################################
# CloudWatch Alarms for RDS Primary and Replicas
################################################################################

locals {
  alarm_enabled = var.alarm_sns_topic_arn != ""
}

# --- Primary Instance Alarms ---

resource "aws_cloudwatch_metric_alarm" "primary_cpu_high" {
  count = local.alarm_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-primary-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Primary RDS CPU > 80% for 15 minutes"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "primary_free_storage_low" {
  count = local.alarm_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-primary-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "Primary RDS free storage < 10 GB"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "primary_freeable_memory_low" {
  count = local.alarm_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-primary-freeable-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 536870912 # 512 MB in bytes
  alarm_description   = "Primary RDS freeable memory < 512 MB"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "primary_replica_lag" {
  count = local.alarm_enabled && var.read_replica_count > 0 ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-replica-lag-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 30
  alarm_description   = "Read replica lag > 30 seconds"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "primary_connections_high" {
  count = local.alarm_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-primary-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Primary RDS connections > 80"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = local.common_tags
}
