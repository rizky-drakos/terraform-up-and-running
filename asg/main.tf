/*
  This template defines required resources a cluster of http servers
  managed by an auto scaling group.
*/
provider "aws" {
  region = "ap-south-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

# Enable http requests.
resource "aws_security_group" "instance_sg" {
  name = "instance-sg"
  description = "The security group for instances in the ASG"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Include the default security group (sg-5d14ae2e) to enable SSH connection.
resource "aws_launch_configuration" "my_lunch_config" {
  image_id = "ami-0cecfffd8cae9481c"
  instance_type = "t2.micro"
  key_name = "ap-south-1-key"
  security_groups = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
}

# Get all the available AZs.
data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.my_lunch_config.id
  availability_zones = data.aws_availability_zones.all.names

  min_size = 2
  max_size = 3

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
