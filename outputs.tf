output "instance" {
  value = "${aws_instance.front.public_ip}"
}
