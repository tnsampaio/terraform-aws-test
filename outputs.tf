#It's to show and check mysql address 
output "db_instance_address" {
  value = "${aws_db_instance.redminedb.address}"
}

# Hostname to access REDMINE
output "elb_hostname" {
  value = "${aws_alb.redmine.dns_name}"
}
