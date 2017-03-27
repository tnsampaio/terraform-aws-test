resource "aws_autoscaling_group" "app" {
  name                 = "redmine-asg"
  vpc_zone_identifier  = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]
  min_size             = "1"
  max_size             = "2"
  desired_capacity     = "1"
  launch_configuration = "${aws_launch_configuration.app.name}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml")}"

  vars {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${aws_ecs_cluster.main.name}"
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = "${aws_cloudwatch_log_group.ecs.name}"
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

resource "aws_launch_configuration" "app" {
  security_groups = [
    "${aws_security_group.instance_sg.id}",
  ]

  key_name                    = "${aws_key_pair.admin.id}"
  image_id                    = "${data.aws_ami.stable_coreos.id}"
  instance_type               = "t2.small"
  iam_instance_profile        = "${aws_iam_instance_profile.app.name}"
  user_data                   = "${data.template_file.cloud_config.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

### Security

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = "${aws_vpc.main.id}"
  name   = "tf-ecs-lbsg"

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_security_group" "instance_sg" {
  description = "controls direct access to application instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "Instance security group"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 3000
    to_port   = 3000

    security_groups = [
      "${aws_security_group.lb_sg.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ECS

resource "aws_ecs_cluster" "main" {
  name = "Main-service-cluster"
}

resource "aws_ecs_task_definition" "redmine" {
  family                = "redmine"
  container_definitions = "${data.template_file.task_definition.rendered}"
}

resource "aws_ecs_service" "redmine" {
  name            = "Redmine-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.redmine.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.lbgroup.id}"
    container_name   = "redmine"
    container_port   = "3000"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_alb_listener.front_end",
    "aws_db_instance.redminedb",
    "aws_ecr_repository_policy.redmine_access",
  ]
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/instance-profile-policy.json")}"

  vars {
    app_log_group_arn = "${aws_cloudwatch_log_group.app.arn}"
    ecs_log_group_arn = "${aws_cloudwatch_log_group.ecs.arn}"
  }
}

## ALB

resource "aws_alb_target_group" "lbgroup" {
  name     = "Loab-balanced-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
}

resource "aws_alb" "redmine" {
  name            = "Loab-balancer-redmine"
  subnets         = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.redmine.id}"
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.lbgroup.id}"
    type             = "forward"
  }
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/redmine"
}

resource "aws_ecr_repository" "redmine" {
  name = "redmine"

  provisioner "local-exec" {
    command = "./build-upload-redmine.sh ${var.aws_region}"
  }
}

resource "aws_ecr_repository_policy" "redmine_access" {
  repository = "${aws_ecr_repository.redmine.id}"

  depends_on = [
    "aws_ecr_repository.redmine",
  ]

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Redmine_access_policy_ALLOW",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:*"
            ]
        }
    ]
}
EOF
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url        = "${aws_ecr_repository.redmine.repository_url}"
    container_name   = "redmine"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
    db_name          = "${aws_db_instance.redminedb.name}"
    username         = "${aws_db_instance.redminedb.username}"
    password         = "${var.default_password}"
    db_host          = "${aws_db_instance.redminedb.address}"
  }

  depends_on = [
    "aws_ecr_repository_policy.redmine_access",
  ]
}
