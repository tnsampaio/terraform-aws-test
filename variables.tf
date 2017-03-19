variable "identifier" {
  default     = "redmine"
  description = "Application identifier"
}

variable "storage" {
  default     = "10"
  description = "Initial 10GB size"
}

variable "engine" {
  default     = "mysql"
  description = "Type of the database for redmine"
}

variable "engine_version" {
  description = "Engine version"

  default = {
    mysql = "5.6.27"
  }
}

variable "default_password" {
  description = "Default password for systems"
  default     = "1234aaaAAAsssDDDred"
}

variable "instance_class" {
  default     = "db.t2.micro"
  description = "Free tier Instance class"
}

variable "ami" {
  description = "AWS ECS AMI id"

  default = {
    us-east-1 = "ami-cb2305a1"
  }
}

variable "username" {
  description = "Amazon AWS access key"
}

variable "aws_region" {
  default     = "us-east-1"
  description = "Default AZ Zone"
}

variable "password" {
  description = "password, provide through your ENV variables"
}
