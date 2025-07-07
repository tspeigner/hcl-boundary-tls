output "vault_server_public_ip" {
  description = "The public IP address of the Vault server. It may take 2-3 minutes for the server to be fully initialized after creation."
  value       = aws_instance.server.public_ip
}

output "ansible_run_command" {
  description = "After the instance is ready, run Ansible to configure it. Replace <path_to_private_key> with the path to the private key corresponding to the public_key variable."
  value       = "ansible-playbook -i inventory.ini --private-key ~/.ssh/id_rsa.pub playbook.yml"
}