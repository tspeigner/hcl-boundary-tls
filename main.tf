locals {
  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# NETWORKING
# ------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-subnet"
  })
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-subnet"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = local.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------------------------

resource "aws_security_group" "server" {
  name        = "${var.project_name}-sg"
  description = "Allow traffic to the Vault/Boundary server"
  vpc_id      = aws_vpc.main.id

  # Allow SSH for Ansible/management.
  # In production, restrict this to a bastion or specific management IP range.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Vault UI/API traffic. In production, restrict this.
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # Allow Boundary worker proxy traffic. In production, restrict this.
  # ingress {
  #   from_port   = 9202
  #   to_port     = 9202
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-postgres-sg"
  description = "Allow traffic to the PostgreSQL server"
  vpc_id      = aws_vpc.main.id

  # Ingress rules will be added later to allow access from Vault and Boundary workers.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows DB to fetch packages if needed
  }

  tags = local.tags
}

# ------------------------------------------------------------------------------
# BOUNDARY
# ------------------------------------------------------------------------------

# resource "boundary_worker_token" "main" {
#   # This creates an activation token for a new self-hosted worker.
#   # The worker will use this token on its first startup to register itself.
#   scope_id = var.hcp_boundary_project_id
# }

# ------------------------------------------------------------------------------
# COMPUTE
# ------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "main" {
  key_name   = var.project_name
  public_key = var.public_key
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.server.id]

  tags = merge(local.tags, {
    Name = "${var.project_name}-server"
  })
}

# ------------------------------------------------------------------------------
# ANSIBLE
# ------------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.ini.tftpl", {
    server_ip     = aws_instance.server.public_ip
    vault_version = var.vault_version
  })
  filename = "${path.module}/inventory.ini"
}