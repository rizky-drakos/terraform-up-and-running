/*
  This template defines required resources a cluster of http servers
  managed by an auto scaling group.
*/
provider "aws" {
  region = "ap-southeast-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

# Enable http requests.
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  description = "Terraform example sg"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Include the default security group (sg-5d14ae2e) to enable SSH connection.
resource "aws_launch_configuration" "example" {
  image_id = "ami-07c4661e10b404bbb"
  instance_type = "t2.micro"
  key_name = "terraform-example-key"
  security_groups = [aws_security_group.instance.id, "sg-5d14ae2e"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Get all the available AZs.
data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  min_size = 2
  max_size = 3

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
