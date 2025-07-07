#!/bin/bash
set -e

# ---
# This script installs and configures a Vault server.
# It is intended for demo purposes and not for production use.
# It initializes Vault and writes the unseal keys and root token
# to /home/ubuntu/vault-init.json on the instance.
# ---

# Install dependencies
sudo apt-get update
sudo apt-get install -y unzip jq

# Install Vault
curl -sSL https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip -o vault.zip
unzip vault.zip
sudo mv vault /usr/local/bin/
rm vault.zip

# Create Vault user and directories
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo mkdir -p /etc/vault.d
sudo mkdir -p /opt/vault/data

# Create Vault config file
sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
ui = true
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-node-1"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1 # Disabling TLS for demo purposes
}
api_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8200"
cluster_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8201"
EOF

# Set permissions
sudo chown -R vault:vault /etc/vault.d /opt/vault
sudo chmod 640 /etc/vault.d/vault.hcl

# Create systemd service file
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Vault service
sudo systemctl enable vault
sudo systemctl start vault

# Wait for Vault to be ready before initializing
echo "Waiting for Vault to start..."

retries=30
count=0
until curl -s -o /dev/null http://127.0.0.1:8200/v1/sys/health; do
    if [ $count -ge $retries ]; then
        echo "Vault did not start in time. Dumping logs to /home/ubuntu/vault-service-failed.log" >&2
        journalctl -u vault.service --no-pager > /home/ubuntu/vault-service-failed.log
        chown ubuntu:ubuntu /home/ubuntu/vault-service-failed.log
        exit 1
    fi
    sleep 2
    count=$((count + 1))
done
echo "Vault is up and running."

# Initialize and unseal
export VAULT_ADDR="http://127.0.0.1:8200"
vault operator init -key-shares=1 -key-threshold=1 -format=json > /tmp/vault-init.json
cp /tmp/vault-init.json /home/ubuntu/vault-init.json
chown ubuntu:ubuntu /home/ubuntu/vault-init.json
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[0]" /tmp/vault-init.json)
vault operator unseal $VAULT_UNSEAL_KEY

# # ---
# # Install and configure Boundary Worker
# # ---

# # Install Boundary
# curl -sSL https://releases.hashicorp.com/boundary/BOUNDARY_VERSION/boundary_BOUNDARY_VERSION_linux_amd64.zip -o boundary.zip
# unzip boundary.zip
# sudo mv boundary /usr/local/bin/
# rm boundary.zip

# # Create Boundary user and directories
# sudo useradd --system --home /etc/boundary.d --shell /bin/false boundary
# sudo mkdir -p /etc/boundary.d

# # Create Boundary worker config file.
# # It will use the activation token on its first run to register with the cluster.
# sudo tee /etc/boundary.d/worker.hcl > /dev/null <<EOF
# disable_mlock = true
# listener "tcp" {
#   address = "0.0.0.0:9202"
#   purpose = "proxy"
# }
# worker {
#   auth_storage_path = "/etc/boundary.d/worker_auth"
#   controller_generated_activation_token = "$${boundary_activation_token}"
#   tags {
#     type    = "self-hosted"
#     project = "${project_name}"
#   }
# }
# EOF

# # Set permissions
# sudo chown -R boundary:boundary /etc/boundary.d
# sudo chmod 640 /etc/boundary.d/worker.hcl

# # Create systemd service file for Boundary worker
# sudo tee /etc/systemd/system/boundary-worker.service > /dev/null <<EOF
# [Unit]
# Description="HashiCorp Boundary Worker"
# Requires=network-online.target
# After=network-online.target
# [Service]
# User=boundary
# Group=boundary
# ExecStart=/usr/local/bin/boundary server -config=/etc/boundary.d/worker.hcl
# Restart=on-failure
# [Install]
# WantedBy=multi-user.target
# EOF

# # Start and enable Boundary worker service
# sudo systemctl enable boundary-worker
# sudo systemctl start boundary-worker