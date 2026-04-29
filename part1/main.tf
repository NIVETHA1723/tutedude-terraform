data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "part1_sg" {
  name        = "part1-sg"
  description = "Security group for Part 1"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2_part1" {
  source             = "../modules/ec2"
  instance_name      = "part1-single-ec2"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.part1_sg.id]
  user_data          = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip nodejs npm git

              # Setup Flask
              mkdir -p /app/flask
              cat <<EOT > /app/flask/app.py
              from flask import Flask, jsonify
              app = Flask(__name__)
              @app.route('/')
              def hello(): return jsonify(message="Hello from Part 1 Flask!")
              @app.route('/api')
              def api(): return jsonify(status="success", data="Part 1 API Data")
              if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)
              EOT
              pip3 install flask
              nohup python3 /app/flask/app.py > /app/flask/app.log 2>&1 &

              # Setup Express
              mkdir -p /app/express
              cd /app/express
              npm init -y
              npm install express axios
              cat <<EOT > /app/express/app.js
              const express = require('express');
              const app = express();
              app.get('/', (req, res) => res.send('<h1>Hello from Part 1 Express!</h1>'));
              app.listen(3000, '0.0.0.0');
              EOT
              nohup node /app/express/app.js > /app/express/app.log 2>&1 &
              EOF
}

output "public_ip" {
  value = module.ec2_part1.public_ip
}
