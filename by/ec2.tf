data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf install -y nginx
    echo '<h1>Tarea 3: EC2 con Nginx funcionando</h1>' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  tags = { Name = "${var.project_name}-nginx" }
}

