variable "environment" {
  type    = string
  default = "test"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "az" {
  default = ["a", "b", "c"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "app_port" {
  type    = number
  default = 5000
}

variable "tags" {
  type = map(string)
  default = {
    Name = "test"
    env  = "test"
  }
}

variable "elb_healthcheck" {
  type = map(number)
  default = {
    interval = 5
    timeout  = 2
  }
}

variable "asg_health_check_elb_enabled" {
  type    = bool
  default = true
}

variable "app_nodes_num" {
  type    = number
  default = 2
}
