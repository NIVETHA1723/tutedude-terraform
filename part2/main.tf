data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "part2-backend-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "frontend_sg" {
  name        = "part2-frontend-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
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

module "backend" {
  source             = "../modules/ec2"
  instance_name      = "part2-backend"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.backend_sg.id]
  user_data          = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip
              pip3 install flask
              cat <<EOT > app.py
              from flask import Flask, jsonify
              app = Flask(__name__)
              @app.route('/api')
              def api(): return jsonify(message="Backend Data from Part 2")
              if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)
              EOT
              nohup python3 app.py > app.log 2>&1 &
              EOF
}

module "frontend" {
  source             = "../modules/ec2"
  instance_name      = "part2-frontend"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.frontend_sg.id]
  user_data          = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nodejs npm
              mkdir -p /app
              cd /app
              npm init -y
              npm install express axios
              cat <<EOT > app.js
              const express = require('express');
              const axios = require('axios');
              const app = express();
              const BACKEND_URL = 'http://${module.backend.private_ip}:5000';
              app.get('/', async (req, res) => {
                try {
                  const resp = await axios.get(`${BACKEND_URL}/api`);
                  res.send(`<h1>Frontend</h1><p>Data from backend: ${JSON.stringify(resp.data)}</p>`);
                } catch (e) {
                  res.send(`<h1>Error</h1><p>${e.message}</p>`);
                }
              });
              app.listen(3000, '0.0.0.0');
              EOT
              nohup node app.js > app.log 2>&1 &
              EOF
}

output "backend_public_ip" {
  value = module.backend.public_ip
}

output "frontend_public_ip" {
  value = module.frontend.public_ip
}
