.SHELL: bash

DO_TOKEN := $(shell cat ./creds/do_token)
S3_KEY := $(shell cat ./creds/s3_key)
S3_SECRET := $(shell cat ./creds/s3_secret)
KUBECONFIG := $(shell cat ./creds/primary-kubeconfig.yaml)
ROOT_PUBLIC_SSH := $(shell cat ./creds/root_public_ssh)

.PHONY: help
help: ## List all available targets with help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ========== TERRAFORM ==========
.PHONY: terraform_init
terraform_init: ## Init terraform project in your local machine
	@terraform -chdir=./terraform init -reconfigure -backend-config="access_key=$(S3_KEY)" -backend-config="secret_key=$(S3_SECRET)"

.PHONY: terraform_plan
terraform_plan: ## Create plan of infrastructure changes
	@terraform -chdir=./terraform plan -var="do_token=$(DO_TOKEN)" -var="root_public_ssh=$(ROOT_PUBLIC_SSH)"

.PHONY: terraform_apply
terraform_apply: ## Apply plan of infrastructure changes
	@terraform -chdir=./terraform apply --auto-approve -var="do_token=$(DO_TOKEN)" -var="root_public_ssh=$(ROOT_PUBLIC_SSH)"

.PHONY: terraform_destroy
terraform_destroy: ## Destroy your infrastructure which was created via this project state fully
	@terraform -chdir=./terraform destroy --auto-approve -var="do_token=$(DO_TOKEN)" -var="root_public_ssh=$(ROOT_PUBLIC_SSH)"
# ========== TERRAFORM END ==========

# ========== KUBERNETES UTILS ==========
.PHONY: external_dns_deploy
external_dns_deploy: ## Deploy external-dns
	@kubectl --kubeconfig=./creds/primary-kubeconfig.yaml apply -f ./kubernetes/deployments/external-dns/deployment.yaml 

.PHONY: external_dns_check
external_dns_check: ## Check external-dns pod's status
	@kubectl --kubeconfig=./creds/primary-kubeconfig.yaml get pods

.PHONY: external_dns_rollback
external_dns_rollback: ## Delete external-dns from cluster
	@kubectl --kubeconfig=./creds/primary-kubeconfig.yaml delete -f ./kubernetes/deployments/external-dns/deployment.yaml 

.PHONY: public_ingress_deploy
public_ingress_deploy: # Deploy public nginx-ingress controller
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml upgrade --install -n nginx-ingress --create-namespace -f ./kubernetes/charts/public-ingress/values.yaml nginx-ingress-controller oci://registry-1.docker.io/bitnamicharts/nginx-ingress-controller

.PHONY: public_ingress_rollback
public_ingress_rollback: # Delete public nginx-ingress controller
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml uninstall -n nginx-ingress nginx-ingress-controller

.PHONY: private_ingress_deploy
private_ingress_deploy: # Deploy private nginx-ingress controller
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml upgrade --install -n nginx-ingress --create-namespace -f ./kubernetes/charts/private-ingress/values.yaml private-nginx-ingress-controller oci://registry-1.docker.io/bitnamicharts/nginx-ingress-controller

.PHONY: private_ingress_rollback
private_ingress_rollback: # Delete private nginx-ingress controller
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml uninstall -n private-nginx-ingress nginx-ingress-controller

.PHONY: ingress_check
ingress_check: # Check nginx-ingress controller
	@kubectl --kubeconfig=./creds/primary-kubeconfig.yaml -n nginx-ingress get pods

.PHONY: pgadmin_deploy
pgadmin_deploy: # Deploy pgadmin to kubernetes
	@helm repo add runix https://helm.runix.net
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml upgrade --install pgadmin runix/pgadmin4 --create-namespace -n pgadmin -f ./kubernetes/charts/pgadmin/values.yaml

.PHONY: pgadmin_rollback
pgadmin_rollback: # Delete pgadmin to kubernetes
	@helm --kubeconfig=./creds/primary-kubeconfig.yaml uninstall -n pgadmin pgadmin
# ========== KUBERNETES UTILS END ==========

# ========== ANSIBLE ==========
.PHONY: new_hosts_setup
new_hosts_setup: # Setup new hosts
	@cd ./ansible && ansible-playbook -D -vvv -i ./inventory/hosts.ini ./playbooks/setup-new-hosts.yaml -u root

.PHONY: haproxy_setup
haproxy_setup: # Deploy haproxy
	@cd ./ansible && ansible-playbook -D -vvv -i ./inventory/hosts.ini ./playbooks/setup-haproxy.yaml -u root

.PHONY: wireguard_setup
wireguard_setup: # Deploy wireguard (wg-easy)
	@cd ./ansible && ansible-playbook -D -vvv -i ./inventory/hosts.ini ./playbooks/setup-wireguard.yaml -u root

.PHONY: ufw_setup
ufw_setup: # Setup UFW rules
	@cd ./ansible && ansible-playbook -D -vvv -i ./inventory/hosts.ini ./playbooks/setup-ufw.yaml -u root
# ========== ANSIBLE END ==========
