variable "subnet_1_cidr" {
	default     = "172.20.245.0/24"
	description = "Your AZ"
}

variable "subnet_2_cidr" {
	default     = "172.20.246.0/24"
	description = "Your AZ"
}

variable "az_1" {
	default     = "us-east-1a"
	description = "Your Az1, use AWS CLI to find your account specific"
}

variable "az_2" {
	default     = "us-east-1d"
	description = "Your Az2, use AWS CLI to find your account specific"
}
