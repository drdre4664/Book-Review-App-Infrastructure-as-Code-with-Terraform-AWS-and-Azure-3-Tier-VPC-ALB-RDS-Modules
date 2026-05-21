data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  web_user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx nodejs npm git
    cd /home/ubuntu
    git clone https://github.com/pravinmishraaws/book-review-app.git
    cd book-review-app/frontend
    echo "NEXT_PUBLIC_API_URL=http://${var.internal_alb_dns}:3001" > .env.production
    npm install
    npm run build
    cat <<SYSD > /etc/systemd/system/frontend.service
    [Unit]
    Description=Next.js Frontend
    After=network.target
    [Service]
    WorkingDirectory=/home/ubuntu/book-review-app/frontend
    ExecStart=/usr/bin/npm run start
    Restart=always
    Environment=PORT=3000
    [Install]
    WantedBy=multi-user.target
    SYSD
    systemctl enable frontend
    systemctl start frontend
    cat <<NGINX > /etc/nginx/sites-available/default
    server {
        listen 80;
        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
        }
    }
    NGINX
    systemctl restart nginx
  EOF

  app_user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nodejs npm git
    cd /home/ubuntu
    git clone https://github.com/pravinmishraaws/book-review-app.git
    cd book-review-app/backend
    cat <<ENV > .env
    DB_HOST=${var.db_host}
    DB_NAME=${var.db_name}
    DB_USER=${var.db_username}
    DB_PASS=${var.db_password}
    DB_DIALECT=mysql
    PORT=3001
    JWT_SECRET=${var.jwt_secret}
    ALLOWED_ORIGINS=http://${var.public_alb_dns}
    ENV
    npm install
    cat <<SYSD > /etc/systemd/system/backend.service
    [Unit]
    Description=Node.js Backend
    After=network.target
    [Service]
    WorkingDirectory=/home/ubuntu/book-review-app/backend
    ExecStart=/usr/bin/node src/server.js
    Restart=always
    EnvironmentFile=/home/ubuntu/book-review-app/backend/.env
    [Install]
    WantedBy=multi-user.target
    SYSD
    systemctl enable backend
    systemctl start backend
  EOF
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.web_subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  key_name               = var.key_name
  user_data              = local.web_user_data
  tags                   = { Name = "${var.project_name}-web-ec2" }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.app_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  key_name               = var.key_name
  user_data              = local.app_user_data
  tags                   = { Name = "${var.project_name}-app-ec2" }
}
