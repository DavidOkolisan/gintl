
# GINTL
Repo contains DevOps example project including k8s, infrastructure as well as CI/CD setup. 
Base repo containing apps and initial k8s manifest can be found [here](https://github.com/Azure-
Samples/aks-store-demo) 

# Local setup and testing
## Prerequisite
- [Minikube setup](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download)
- Docker
- App dependencies (described in README for each app specifically in src dir)
- Terraform
- Azure account
- Git

## Build and test
1. Setup minikube ingress `minikube addons enable ingress`
2. Run local environment setup with mode kube or helm `./local-test.sh start ${mode}`
3. Open minikube tunnel `minikube tunnel` in another session/terminal
4. Execute test `./local-test.sh execute` or open `http://localhost:80` in browser
5. Run cleanup `./local-test.sh cleanup`
6. Close started minikube tunnel(Ctrl+C) or kill minikube tunnel process `kill $(ps aux | grep "minikube tunnel" | awk '{print $2}')`
**NOTE**: Minikube is known to have bugs in case you get message like
```
Exiting due to TUNNEL_ALREADY_RUNNING: Another tunnel process is already running, terminate the existing instance to start a new one
```
Restart minikube with `minikube stop` and `minikube start`
 

# Infrastructure setup
**NOTE**:Current setup assumes single environment, and this was executed locally, should run in CD manner as well
1. run `az login` to log to Azure
2. run **only once** `./infra-boostrap.sh` to boost resource group and blob setup for terraform remote state storage
3. run **only once** `./infra-cleanup.sh` for cleaning resources
4. run inside infra directory (can pass subscription id as argument or export it as env variable `export TF_VAR_subscription_id=`)
```
terraform init
terraform validate
terraform plan -var="subscription_id={your-azure-subscription-id}"
terraform apply -var="subscription_id={your-azure-subscription-id}"
```

# Test connection to AKS (from local)
1. Connect to AKS executing following cmd
```
az aks get-credentials --resource-group "dev-rg" --name dev-store-cluster
```
2. Run `kubectl apply -f main.yaml` from `k8s` dir
3. And then you can get nginx IP
```
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# or get it from following command
kubectl get ingress
```
3. In order to access `store-front.example.com` as per current k8s [manifest file](./k8s/main.yaml) you need to 
add to `/etc/hosts` file following line `${your_nginx_ip_address}  store.example.com`

# CI/CD
### Azure DevOps 
Procedure defined when Azure DevOps for CI/CD, we used Git actions though which 
offers more flexibility (next section)
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
6. Create pipelines for app build, deploying to ACR and updating AKS with new images (yaml files)
**Note**: Since test are not working as supposed (`npm test` ie) this approach is abandoned and git actions 
are used instead.

### Git Actions
1. Get credential needed for git actions `./git_actions_spn_setup.sh`
2. Configure secrets for Git Actions (credentials are mandatory, resource names not)
   ```
   Go to Repo Settings > Secrets > Actions and add:
   AZURE_CREDENTIALS (paste json response from previous command)
   ACR_LOGIN_SERVER (ie. myacr.azurecr.io)
   AKS_RESOURCE_GROUP (ie dev-rg)
   AKS_CLUSTER_NAME (ie dev-store-cluster)
   ```
3. Execute pipeliens under git repo -> Actions -> Select pipeline on the left -> Run workflow
4. Check if images successfully uploaded to ACR by checking repositories on your ACR cluster page or by running
```
az acr repository list --name <your-acr-name> --output table
```
5. Get nginx external-ip, by founding it on you aks resource page or by executing command
```
# Get <EXTERNAL-IP>
kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer
```
6. Access it via host name in nginx setup in [k8s config file][./k8s/main.yaml]
```
# in this case local hosts file update is required or k8s dns setup
sudo nano /etc/hosts
# add following line
<EXTERNAL-IP> store-front.example.com
```
or remove host from config file and just access it by <EXTERNAL-IP>

### TBD - Helm charts setup
Setup referencing helm charts can be found in [helm](./helm) directory. This can be run by:
1. Run manually `helm upgrade store-app ./store-app -f values-local.yaml --dry-run --debug`
2. Using script `./local-test.sh start helm` (as described in [Local run section](#build-and-test))

# Further improvements
1. Implement cicd for infrastructure/terraform setup
2. Implement multi account/environment support with corresponding cicd pipelines per environment
3. Tighten security rules and bastion access to specific network
4. Apps are missing test cases or test are failing, so for each app testing should be implemented and
and documented in order to be performed while building images

# Cleanup kubectl (optional)
1. Switch to minikube context `kubectl config use-context minikube`
2. Get contexts `kubectl config get-contexts`
3. Delete specific context(name usually is the same as cluster name) `kubectl config delete-context ${aks_cluster_name}`
4. Get clusters `kubectl config get-clusters`
5. Delete specific cluster `kubectl config delete-cluster ${aks_cluster_name}`
6. Get users `kubectl config get-users`
7. Unset user `kubectl config unset users.clusterUser_${aks_resource_group}_${aks_cluster_name}`