resource "aws_ecs_cluster" "redmine" {
  name = "ecs-redmine"
}

resource "aws_ecr_repository" "images" {
  name = "images"

  provisioner "local-exec" {
    command = "./build-upload-images.sh"
  }
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url      = "images:redmine"
    container_name = "redmine"
  }
}

resource "template_file" "cluster_data" {
  template = "templates/command_cluster"

  vars {
    cluster_name = "ecs-redmine"
  }
}

resource "aws_elb" "redmine_elb" {
  name                      = "redmine-elb"
  subnets                   = ["${aws_subnet.subnet_2.id}", "${aws_subnet.subnet_1.id}"]
  connection_draining       = true
  cross_zone_load_balancing = true

  security_groups = [
    "${aws_security_group.allow_all.id}",
  ]

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 3000
    lb_protocol       = "http"
  }

  depends_on = [
    "aws_subnet.subnet_1",
    "aws_subnet.subnet_2",
  ]
}

resource "aws_ecs_task_definition" "redmine" {
  family                = "redmine_family"
  container_definitions = "${data.template_file.task_definition.rendered}"
}

resource "aws_ecs_service" "redmine-prod" {
  name            = "redmine-prod-inst"
  cluster         = "${aws_ecs_cluster.redmine.id}"
  task_definition = "${aws_ecs_task_definition.redmine.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs_elb.arn}"

  load_balancer {
    elb_name       = "${aws_elb.redmine_elb.id}"
    container_name = "redmine"
    container_port = 3000
  }
}

resource "aws_launch_configuration" "ecs_cluster" {
  name                 = "ecs_cluster_conf"
  instance_type        = "t2.micro"
  image_id             = "${lookup(var.ami, var.aws_region)}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"

  security_groups = [
    "${aws_security_group.allow_all.id}",
  ]

  user_data = "${template_file.cluster_data.rendered}"

  key_name = "${aws_key_pair.tiago.key_name}"
}

resource "aws_iam_instance_profile" "ecs" {
  name  = "ecs-profile"
  roles = ["${aws_iam_role.ecs.name}"]
}

resource "aws_autoscaling_group" "ecs_cluster" {
  name                 = "ecs-cluster"
  vpc_zone_identifier  = ["${aws_subnet.subnet_2.id}", "${aws_subnet.subnet_1.id}"]
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.ecs_cluster.name}"
  health_check_type    = "EC2"
}
