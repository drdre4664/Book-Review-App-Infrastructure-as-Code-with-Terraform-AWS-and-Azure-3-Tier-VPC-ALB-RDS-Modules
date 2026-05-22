# Book Review App — Infrastructure as Code with Terraform (AWS & Azure, 3-Tier, VPC, ALB, RDS, Modules)

> **Part 2 of 2 — Terraform Progression** · This repo demonstrates **multi-cloud modular design** (4 reusable modules, AWS↔Azure resource mapping, circular-dependency resolution). For the single-cloud Azure foundation this builds on, see [Terraform-AWS-3-Tier-Infrastructure-VPC-ALB-AutoScaling-RDS](https://github.com/drdre4664/Terraform-AWS-3-Tier-Infrastructure-VPC-ALB-AutoScaling-RDS).

Full infrastructure for a production-grade 3-tier deployment of the Book Review App, written entirely in Terraform for both AWS and Azure. The infrastructure is split into reusable modules — networking, database, load balancer, and compute — so each layer is independently manageable and clearly separated.

The same module structure is used for both cloud providers to demonstrate that Terraform concepts are platform-agnostic. The resource names are different but the architecture, the module design, and the dependency chain are identical.

---

## Architecture

```
                          Internet
                             │
                             ▼
              [Public ALB / Public LB]            <-- module.load_balancer
                             │
                             ▼
            [Web Tier VM — Nginx + Next.js]       <-- module.compute (public subnet)
                             │
                             ▼
             [Internal ALB / Internal LB]         <-- module.load_balancer
                             │
                             ▼
              [App Tier VM — Node.js]             <-- module.compute (private subnet)
                             │
                             ▼
            [RDS MySQL / Azure MySQL]             <-- module.database (private subnet)
```

---

## What are Terraform Modules?

A Terraform module is a folder of `.tf` files that groups related resources together. Instead of writing every resource in one long `main.tf`, modules let you:

- **Separate concerns** — networking code lives in the networking module, database code in the database module
- **Reuse code** — call the same module with different inputs for dev and prod environments
- **Hide complexity** — the root `main.tf` reads like a high-level blueprint; the details live inside each module
- **Test independently** — each module can be validated and tested on its own

This project has 4 modules per cloud provider:

| Module          | AWS creates                                          | Azure creates                                          |
|-----------------|------------------------------------------------------|--------------------------------------------------------|
| `networking`    | VPC, 6 subnets, IGW, NAT Gateway, route tables, 5 SGs | Resource Group, VNet, 6 subnets, 3 NSGs               |
| `database`      | RDS MySQL Multi-AZ + Read Replica                    | MySQL Flexible Server + Read Replica                   |
| `load_balancer` | Public ALB + Internal ALB + target groups            | Public LB + Internal LB + backend pools                |
| `compute`       | Web Tier EC2 + App Tier EC2                          | Web Tier VM + App Tier VM                              |

---

## Module Design Decisions

### Why are target group attachments in the root module?

The compute module needs the ALB/LB DNS to write to `user_data` at creation time. The load balancer needs the instance/NIC IDs to register targets. This is a circular dependency.

**Solution:** The `load_balancer` module creates the ALBs and backend pools without attaching any instances. The `aws_lb_target_group_attachment` (AWS) and `azurerm_network_interface_backend_address_pool_association` (Azure) resources live in the root `main.tf`, which has access to both modules after both are created. This breaks the cycle cleanly.

### Why does compute depend on both database and load_balancer?

The app tier VM `user_data` script needs the database endpoint to write the `.env` file on startup. The web tier `user_data` needs the internal LB IP. Both must exist before the VMs are created. `depends_on` enforces this ordering.

### Why is security group chaining done inside the networking module?

All security groups are in one module so they can reference each other directly. On AWS, each SG references the one above it by ID (e.g. `source_group = web_sg`). On Azure, NSGs use subnet CIDRs as source since Azure NSGs reference address prefixes rather than other NSG IDs.

---

## Project Structure

```
.
├── aws/
│   ├── main.tf                  # Root — calls all 4 modules + target attachments
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── networking/
│       │   ├── main.tf          # VPC, subnets, IGW, NAT, route tables, SGs
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── database/
│       │   ├── main.tf          # RDS MySQL Multi-AZ + Read Replica
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── load_balancer/
│       │   ├── main.tf          # Public ALB + Internal ALB + target groups
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── compute/
│           ├── main.tf          # Web EC2 + App EC2 with user_data
│           ├── variables.tf
│           └── outputs.tf
│
├── azure/
│   ├── main.tf                  # Root — calls all 4 modules + NIC associations
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── networking/
│       │   ├── main.tf          # Resource Group, VNet, subnets, NSGs
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── database/
│       │   ├── main.tf          # MySQL Flexible Server + Read Replica
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── load_balancer/
│       │   ├── main.tf          # Public LB + Internal LB + backend pools
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── compute/
│           ├── main.tf          # Web VM + App VM with custom_data
│           ├── variables.tf
│           └── outputs.tf
│
└── README.md
```

---

## AWS vs Azure — Terraform Resource Mapping

| Concept                  | AWS Resource                  | Azure Resource                          |
|--------------------------|-------------------------------|------------------------------------------|
| Virtual Network          | `aws_vpc`                     | `azurerm_virtual_network`               |
| Subnet                   | `aws_subnet`                  | `azurerm_subnet`                        |
| Firewall Rules           | `aws_security_group`          | `azurerm_network_security_group`        |
| Internet Gateway         | `aws_internet_gateway`        | Built into VNet                          |
| NAT Gateway              | `aws_nat_gateway`             | `azurerm_nat_gateway`                   |
| Public Load Balancer     | `aws_lb` (internet-facing)    | `azurerm_lb` + `azurerm_public_ip`     |
| Internal Load Balancer   | `aws_lb` (internal)           | `azurerm_lb` (private IP)               |
| Virtual Machine          | `aws_instance`                | `azurerm_linux_virtual_machine`         |
| VM startup script        | `user_data`                   | `custom_data` (base64 encoded)          |
| Managed Database         | `aws_db_instance`             | `azurerm_mysql_flexible_server`         |
| Resource Grouping        | Tags                          | `azurerm_resource_group`                |

---

## Prerequisites

**AWS:**

- Terraform >= 1.0
- AWS CLI configured (`aws configure`)
- EC2 key pair created

**Azure:**

- Terraform >= 1.0
- Azure CLI installed and logged in (`az login`)
- SSH key at `~/.ssh/id_rsa.pub`

---

## How to Deploy

### AWS

```bash
cd aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in key_name, db_password, jwt_secret

terraform init
terraform plan
terraform apply

terraform output public_alb_dns
```

### Azure

```bash
cd azure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in db_password, jwt_secret

terraform init
terraform plan
terraform apply

terraform output public_lb_ip
```

### Destroy when done (avoid charges)

```bash
terraform destroy
```

---

## Security Group / NSG Chain

```
AWS:
  Public ALB SG     ← inbound 80   from 0.0.0.0/0
  Web Tier SG       ← inbound 80   from Public ALB SG only
  Internal ALB SG   ← inbound 3001 from Web Tier SG only
  App Tier SG       ← inbound 3001 from Internal ALB SG only
  DB Tier SG        ← inbound 3306 from App Tier SG only

Azure:
  Web NSG           ← inbound 80   from Internet
  App NSG           ← inbound 3001 from 10.0.1.0/23 (web subnet) only
  DB NSG            ← inbound 3306 from 10.0.3.0/23 (app subnet) only
```

---

## Key Lessons Learned

| Problem | Root Cause | Fix |
|---|---|---|
| Circular dependency between compute and load_balancer | Compute needs LB DNS, LB needs instance IDs | Move target group attachments to root `main.tf` — LB module creates pools only |
| Azure MySQL subnet delegation required | Flexible Server requires subnet delegated to `Microsoft.DBforMySQL/flexibleServers` | Add `delegation` block inside `azurerm_subnet` for DB subnets |
| Azure VM `custom_data` must be base64 encoded | Azure requires base64, AWS accepts raw script | Wrap Azure user_data in `base64encode()` |
| RDS read replica fails with subnet group | Read replica inherits subnet group from source | Remove `db_subnet_group_name` from replica resource |
| Private DNS zone required for Azure MySQL VNet integration | MySQL Flexible Server needs private DNS to resolve within VNet | Create `azurerm_private_dns_zone` and link it to VNet before creating server |
| `sensitive = true` variables not shown in plan output | Intentional — prevents credentials appearing in CI/CD logs | Mark `db_password` and `jwt_secret` as `sensitive = true` |

---

## Design Principles

**Modules make infrastructure readable** — the root `main.tf` reads like a blueprint with 4 clear layers. The details of how each is built live inside the module, not at the root.

**Outputs and inputs wire modules together** — one module's output becomes another module's input. The database module outputs `db_endpoint`, which feeds into the compute module so the app tier knows where to connect.

**Circular dependencies require intentional design** — when two modules need each other's outputs, you need to find the right split point. Moving backend pool attachments out of the load balancer module was the solution.

**AWS SG chaining vs Azure NSG CIDRs** — AWS security groups can reference each other by ID, which is more precise. Azure NSGs reference source IP ranges, so you use subnet CIDRs instead. Same concept, different implementation.

**`terraform destroy` before closing your laptop** — RDS Multi-AZ, NAT Gateway, and Azure MySQL Flexible Server are the most expensive resources. Always destroy when done testing.

---

## Tools Used

**AWS:** VPC, EC2, ALB (public + internal), RDS MySQL Multi-AZ + Read Replica, Security Groups, NAT Gateway, Terraform `~> 5.0` AWS Provider

**Azure:** VNet, Virtual Machines, Load Balancer (public + internal), MySQL Flexible Server + Read Replica, NSG, Private DNS Zone, Terraform `~> 3.0` AzureRM Provider
