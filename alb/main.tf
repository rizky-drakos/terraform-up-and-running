/*
  This template defines required resources a cluster of http servers
  standing behind an application load balancer.
*/
provider "aws" {
  region = "ap-south-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

# Only allow http requests from application_lb_sg, which includes my_application_lb.
resource "aws_security_group" "target_sg" {
  name = "target-sg"
  description = "The security group for the registered targets"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    security_groups = [aws_security_group.application_lb_sg.id]
  }
}

# Enable http requests from the internet, and allow outbound access to the target_sg, 
# which includes registered targets.
resource "aws_security_group" "application_lb_sg" {
  name = "application-lb-sg"
  description = "The security group for the application load balancer"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create two instances.
resource "aws_instance" "my_instance_a" {
  ami = "ami-0cecfffd8cae9481c"
  instance_type = "t2.micro"
  key_name = "ap-south-1-key"
  vpc_security_group_ids = [aws_security_group.target_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "instance_a"
  }
}

resource "aws_instance" "my_instance_b" {
  ami = "ami-0cecfffd8cae9481c"
  instance_type = "t2.micro"
  key_name = "ap-south-1-key"
  vpc_security_group_ids = [aws_security_group.target_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "instance_b"
  }
}

# Get the default vpc.
data "aws_vpc" "default_vpc" {
  default = true
}

# Create a target group.
resource "aws_lb_target_group" "my_target_group" {
  name = "my-target-group"
  target_type = "instance"
  port = var.server_port
  protocol = "HTTP"
  # The VPC containing the instances you want to choose from for inclusion in this target group.  
  vpc_id = data.aws_vpc.default_vpc.id
}

# Attach instance_a to the target group.
resource "aws_lb_target_group_attachment" "my_target_group_attachment_a" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id = aws_instance.my_instance_a.id
  port = var.server_port
}

# Attach instance_b to the target group.
resource "aws_lb_target_group_attachment" "my_target_group_attachment_b" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id = aws_instance.my_instance_b.id
  port = var.server_port
}

resource "aws_lb" "my_application_lb" {
  name = "my-application-lb"
  internal  = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.application_lb_sg.id]
  subnets = ["subnet-d7fc909b", "subnet-737dcb08", "subnet-38665850"]
}

resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_application_lb.arn
  port = var.server_port
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
