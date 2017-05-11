provider "aws" {
  region     = "${var.aws_region}"
  secret_key = "${var.password}"
  access_key = "${var.username}"
}

resource "aws_db_instance" "redminedb" {
  depends_on             = ["aws_security_group.internal_access"]
  identifier             = "${var.identifier}"
  allocated_storage      = "${var.storage}"
  engine                 = "${var.engine}"
  engine_version         = "${lookup(var.engine_version, var.engine)}"
  instance_class         = "${var.instance_class}"
  name                   = "redmine"
  username               = "redmine"
  password               = "${var.default_password}"
  vpc_security_group_ids = ["${aws_security_group.internal_access.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.default.id}"
  skip_final_snapshot    = true

}

resource "aws_instance" "front" {
  ami           = "ami-0b33d91d"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnet_1.id}"

  vpc_security_group_ids = [
    "${aws_security_group.web.id}",
  ]

  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.id}"

  tags {
    Name = "NGINX PROXY"
  }

  provisioner "local-exec" {
    command = "sleep 60 && export ANSIBLE_HOST_KEY_CHECKING=False && echo \"[webserver]\n${aws_instance.front.public_ip}\" > /tmp/inventory_ws && ansible-playbook -i /tmp/inventory_ws -e ansible_user=ec2-user -e redmine_elb_addr=${aws_alb.redmine.dns_name} playbooks/webserver.yml"
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "redmine_subnet_group"
  description = "Redmine subnets"
  subnet_ids  = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]
}

resource "aws_vpc" "main" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = 1

  tags {
    Name = "main"
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "Admin's ssh key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAomgAhg2r3ZXXeh8trnTjAnR7F53VcMA1eHkBRgSKW2n+i0sEXXKIt9bGs4JXaqdYFPnpIfx1gGSayUBpZtGZue+d1yy3CC/V9/7rG7wwJGTjTXb843PQcQqFUFVx2TN6iEDz8YlYgFF42vR25k75W3DbnLSNolHYPE5H/gT0T18iBwcK70BH6cz2lILCOYTDQsozEt8m3ZbOi6HK9B8Lev9Gymh/RPISiigH6JfnsbTLBUMd2EiuSUBXiQPIGJ7Y2tCGyXcpmF41ax3cp56V6ByoddjmnpjvDSB+0Qjb9SBXlOIONR93ay3/hI+YwZz7K7cVXYBpBwA3fY+qTIIf Tiago N Sampaio"
}

output "redmine" {
  value = "${aws_instance.front.address}"
}
