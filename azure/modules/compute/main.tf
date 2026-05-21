locals {
  web_user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx nodejs npm git
    cd /home/${var.admin_username}
    git clone https://github.com/pravinmishraaws/book-review-app.git
    cd book-review-app/frontend
    echo "NEXT_PUBLIC_API_URL=http://${var.internal_lb_ip}:3001" > .env.production
    npm install
    npm run build
    cat <<SYSD > /etc/systemd/system/frontend.service
    [Unit]
    Description=Next.js Frontend
    After=network.target
    [Service]
    WorkingDirectory=/home/${var.admin_username}/book-review-app/frontend
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
    cd /home/${var.admin_username}
    git clone https://github.com/pravinmishraaws/book-review-app.git
    cd book-review-app/backend
    cat <<ENV > .env
    DB_HOST=${var.mysql_host}
    DB_NAME=${var.db_name}
    DB_USER=${var.db_admin}
    DB_PASS=${var.db_password}
    DB_DIALECT=mysql
    PORT=3001
    JWT_SECRET=${var.jwt_secret}
    ALLOWED_ORIGINS=http://${var.public_lb_ip}
    ENV
    npm install
    cat <<SYSD > /etc/systemd/system/backend.service
    [Unit]
    Description=Node.js Backend
    After=network.target
    [Service]
    WorkingDirectory=/home/${var.admin_username}/book-review-app/backend
    ExecStart=/usr/bin/node src/server.js
    Restart=always
    EnvironmentFile=/home/${var.admin_username}/book-review-app/backend/.env
    [Install]
    WantedBy=multi-user.target
    SYSD
    systemctl enable backend
    systemctl start backend
  EOF
}

# Web Tier NIC
resource "azurerm_network_interface" "web" {
  name                = "${var.project_name}-web-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "web-ip-config"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# App Tier NIC — no public IP
resource "azurerm_network_interface" "app" {
  name                = "${var.project_name}-app-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "app-ip-config"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "${var.project_name}-web-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  custom_data         = base64encode(local.web_user_data)

  network_interface_ids = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "${var.project_name}-app-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  custom_data         = base64encode(local.app_user_data)

  network_interface_ids = [azurerm_network_interface.app.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
