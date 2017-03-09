provider "aws" {
	region = "${var.aws_region}"
	secret_key = "${var.password}"
	access_key = "${var.username}"

}


resource "aws_db_instance" "redminedb" {
	depends_on = ["aws_security_group.internal_access"]
	identifier = "${var.identifier}"
	allocated_storage = "${var.storage}"
	engine = "${var.engine}"
	engine_version = "${lookup(var.engine_version, var.engine)}"
	instance_class = "${var.instance_class}"
	name = "${var.db_name}"
	username = "redmine"
	password = "redmine1234"
	vpc_security_group_ids = ["${aws_security_group.internal_access.id}"]
	db_subnet_group_name = "${aws_db_subnet_group.default.id}"
}

resource "aws_db_subnet_group" "default" {
	name        = "redmine_subnet_group"
	description = "Redmine subnets"
	subnet_ids  = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]
}

resource "aws_vpc" "main" {
	cidr_block = "172.20.0.0/16"

	tags {
		Name = "main"
	}
}
