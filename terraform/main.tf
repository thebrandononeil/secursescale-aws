terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "securescale-vpc"
    Project = "SecureScale"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "securescale-public-a"
    Project = "SecureScale"
    Tier    = "Public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "securescale-public-b"
    Project = "SecureScale"
    Tier    = "Public"
  }
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name    = "securescale-app-a"
    Project = "SecureScale"
    Tier    = "Application"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name    = "securescale-app-b"
    Project = "SecureScale"
    Tier    = "Application"
  }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name    = "securescale-db-a"
    Project = "SecureScale"
    Tier    = "Database"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name    = "securescale-db-b"
    Project = "SecureScale"
    Tier    = "Database"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "securescale-igw"
    Project = "SecureScale"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "securescale-public-rt"
    Project = "SecureScale"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "securescale-nat-eip"
    Project = "SecureScale"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name    = "securescale-nat-gw"
    Project = "SecureScale"
  }

  depends_on = [aws_internet_gateway.main]
}
resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "securescale-app-private-rt"
    Project = "SecureScale"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.app_private.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.app_private.id
}
resource "aws_security_group" "alb" {
  name        = "securescale-alb-sg"
  description = "Allow public web traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "securescale-alb-sg"
    Project = "SecureScale"
  }
}
resource "aws_security_group" "app" {
  name        = "securescale-app-sg"
  description = "Allow application traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "securescale-app-sg"
    Project = "SecureScale"
  }
}
resource "aws_security_group" "db" {
  name        = "securescale-db-sg"
  description = "Allow database traffic only from the application tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from application servers only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name    = "securescale-db-sg"
    Project = "SecureScale"
  }
}
resource "aws_lb" "app" {
  name               = "securescale-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name    = "securescale-alb"
    Project = "SecureScale"
  }
}
resource "aws_lb_target_group" "app" {
  name     = "securescale-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name    = "securescale-app-tg"
    Project = "SecureScale"
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_launch_template" "app" {
  name_prefix   = "securescale-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  user_data = base64encode(file("${path.module}/user-data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "securescale-app"
      Project = "SecureScale"
      Tier    = "Application"
    }
  }

  tags = {
    Name    = "securescale-app-template"
    Project = "SecureScale"
  }
}
resource "aws_autoscaling_group" "app" {
  name = "securescale-app-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "securescale-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "SecureScale"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "securescale-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
resource "aws_db_subnet_group" "main" {
  name = "securescale-db-subnet-group"

  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]

  tags = {
    Name    = "securescale-db-subnet-group"
    Project = "SecureScale"
  }
}
resource "aws_db_instance" "main" {
  identifier = "securescale-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "securescale"
  username = "admin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false

  backup_retention_period = 1

  skip_final_snapshot = true

  tags = {
    Name    = "securescale-db"
    Project = "SecureScale"
  }
}
resource "aws_iam_role" "app" {
  name = "securescale-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "securescale-app-role"
    Project = "SecureScale"
  }
}
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app_secrets" {
  name = "securescale-read-db-secret"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_db_instance.main.master_user_secret[0].secret_arn
      }
    ]
  })
}
resource "aws_iam_instance_profile" "app" {
  name = "securescale-app-profile"
  role = aws_iam_role.app.name

  tags = {
    Name    = "securescale-app-profile"
    Project = "SecureScale"
  }
}
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "securescale-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "securescale-high-cpu"
  alarm_description   = "Alerts when SecureScale ASG average CPU exceeds 80%"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  threshold          = 80
  period             = 300

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name    = "securescale-high-cpu"
    Project = "SecureScale"
  }
}
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "securescale-unhealthy-targets"
  alarm_description = "Alert when the ALB has unhealthy application targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name    = "securescale-unhealthy-targets"
    Project = "SecureScale"
  }
}
# --------------------------------------------------
# Ansible SSM Transfer Bucket
# --------------------------------------------------

resource "aws_s3_bucket" "ansible_ssm" {
  bucket_prefix = "securescale-ansible-ssm-"

  tags = {
    Name    = "securescale-ansible-ssm"
    Project = "SecureScale"
    Purpose = "Ansible SSM temporary file transfer"
  }
}
resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    id     = "cleanup-ansible-temp-files"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}