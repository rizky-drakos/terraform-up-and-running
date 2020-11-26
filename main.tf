provider "aws" {
  region = "ap-southeast-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  description = "Terraform example sg"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami = "ami-07c4661e10b404bbb"
  instance_type = "t2.micro"
  key_name = "terraform-example-key"
  vpc_security_group_ids = [aws_security_group.instance.id, "sg-5d14ae2e"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "terraform-example"
  }
}
