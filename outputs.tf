#It's to show and check mysql address 
output "db_instance_address" {
  value = "${aws_db_instance.redminedb.address}"
}

# Hostname to access ELB redmine
output "elb_hostname" {
  value = "${aws_alb.redmine.dns_name}"
}

#Hostname to access the front to redmine
output "front_redmine" {
  value = "${aws_instance.front.address}"
}
