# Provider
provider "aws" {
  region = var.aws_region
}

# SNS Topic Development
resource "aws_sns_topic" "alarm" {
  name            = "alarm-topic"
  delivery_policy = <<EOF
    {
        "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

# EC2 Instance Development
resource "aws_instance" "my_instance" {

  ami           = data.aws_ami.deb_ami.id
  instance_type = "t2.micro"
}

# EC2 AMI Development
data "aws_ami" "deb_ami" {
  owners      = ["379101102735"]
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-*"]
  }
}


# CloudWatch Metric Alarm Development - CPU Usage
resource "aws_cloudwatch_metric_alarm" "cpu-utilization" {
  alarm_name          = "high_cpu_utilizaion_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilizaion"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = ["aws_sns_topic.alarm.arn"]

  dimensions = {
    InstanceId = aws_instance.my_instance.id
  }
}


# CloudWatch Metric Alarm Development - Health Check
resource "aws_cloudwatch_metric_alarm" "instance-health-check" {
  alarm_name          = "instance-health-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 health status"
  alarm_actions       = aws_sns_topic.alarm.arn

  dimensions = {
    InstanceId = "aws_instance.my_instance.id"
  }
}