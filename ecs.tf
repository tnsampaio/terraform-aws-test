resource "aws_ecs_cluster" "redmine_cluster" {
	name = "Redmine-Cluster"
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
		image_url        = "images:latest"
		container_name   = "redmine"
	}
}

resource "aws_ecs_task_definition" "redmine" {
	family                = "redmine_family"
	container_definitions = "${data.template_file.task_definition.rendered}"
}

resource "aws_ecs_service" "redmine-prod" {
	name         = "redmine-prod-inst"
	cluster         = "${aws_ecs_cluster.redmine_cluster.id}"
	task_definition = "${aws_ecs_task_definition.redmine.arn}"
	desired_count   = 1
}
