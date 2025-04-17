
# Kubernetes
For local testing of k8s resources:
1. If using minikube install ingress addon `minikube addons enable ingress` and `minikube tunnel` (sudo permission required, can be setup in sudoers file just for local test)
2. For Docker Desktop run `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml`
3. In ingress definition under host use `localhost`
4. Run `http://localhost:80`
5. 

# Terraform setup
Current setup assumes only ONE environment
run `az login` to log to Azure
run `./infra-boostrap.sh` to boost resource group and blob setup for terraform remote state storage
run `./infra-cleanup.sh` for cleaning resources


run inside infra directory (can pass subscription id as argument or export it as env variable `export TF_VAR_subscription_id=`)
`terraform init`
`terraform validate`
`terraform plan -var="subscription_id={your-azure-subscription-id}"`
`terraform apply -var="subscription_id={your-azure-subscription-id}"`

- Connect to AKS executing following cmd
```
az aks get-credentials --resource-group "dev-rg" --name dev-store-cluster
```
- And then you can get nginx IP
```
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# or get it from following command
kubectl get ingress
```
- In order to access `store-front.example.com` as per current k8s [manifest file](./k8s/main.yaml) you need to 
add to `/etc/hosts` file following line `${your_nginx_ip_address}  store.example.com`



# CI/CD
Since we are going to use Azure DevOps as our CI/CD tool we need to setup couple things
1. Create new organization (Azure DevOps Organizations -> New organization)
2. Create personal access token (PAT)
   - click on `https://dev.azure.com/{your-organization}/_usersSettings/tokens`
   - create new token
3. run `./spn_setup` to setup service principal used in Azure DevOps
4. Crate new project under Azure DevOps (name `demo` ie)
5. Setup credentials in Azure DevOps
    ```
    Go to Azure DevOps → Pipelines → Library → Variable Groups → + New
    Name: acr-aks-creds
    Add Variables (mark as secret):
    ARM_CLIENT_ID = appId
    ARM_CLIENT_SECRET = password
    ARM_TENANT_ID = tenant
    ACR_NAME = your-acr-name
    ```



Further improvements
1. Implement multi account/environment support with coresponding cicd pipelines per environment
2. Tighten security rules and bastion access to specific network