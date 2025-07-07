--- a/Users/tommy/repos/hcl-boundary-tls/outputs.tf
+++ b/Users/tommy/repos/hcl-boundary-tls/outputs.tf
@@ -6,5 +6,5 @@
 
 output "ansible_run_command" {
   description = "After the instance is ready, run Ansible to configure it. Replace <path_to_private_key> with the path to the private key corresponding to the public_key variable."
-  value       = "ansible-playbook -i inventory.ini --private-key ~/.ssh/id_rsa.pub playbook.yml"
+  value       = "ansible-playbook -i inventory.ini --private-key ~/.ssh/id_rsa playbook.yml"
 }