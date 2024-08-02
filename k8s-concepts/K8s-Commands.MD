### Networking

* Check Cluster Network Information `kubectl cluster-info`

* Get Services: `kubectl get services`

* Describe services : `kubectl describe service <service-name>`

* expose pods as a service : `kubectl expose pod <pod-name> --type=<type> --name=<service-name>`

    - `kubectl expose pod web-pod --type=NodePort --name=my-app-service --port=8080:8080`

    - Other service mode can be `clusterIP` `LoadBalancer` & `NodePort`
* Create an Iggress - `kubectl apply -f ingress.yaml`
* Get ingress - `kubectl get ingress`


### User Management

- List Users (Contexts): `kubectl config get-contexts`

- Set a context (switch user) : `kubectl config use-context <context-name>`

- View Current Context: `kubectl config current-context`

### Storage

- Get PersistentVolumes (PV): `kubectl get pv`

- Get PersistentVolumeClaims (PVC): `kubectl get pvc`

- Describe a PersistentVolumeClaim: `kubectl describe pvc <pvc-name>`

- Create a PVC: `kubectl apply -f pvc.yaml`

### Security

-  Get Roles: `kubectl get roles`

- Get RoleBindings: `kubectl get rolebindings`

- Get Cluster Role : `kubectl get clusterroles`

- Cluster role binding : `kubectl get clusterrolebindings`

- Create Role - `kubectl apply -f role.yaml`

- Create Role Binding - `kubectl apply -f rolebinding.yaml`

- Create a Role for a user with developer : with list, create, update & delete permission
    - `kubectl create role developer --verb=create --verb=get --verb=list --verb=update --verb=delete --resource=pods`
    - here `developer` is the name of the role, we can assign any meaningful name like `admin` `qa-team` etc

    - `--verb=create`, get, update,  delete are the permissions assigned to this role.\

    - `--resource=pods` this means this permission of CRUD can be applied to POD resource, but not on other resource like services, secrets etc

    - If we want this permission for pods & services, we need to add that into that role

    - `--resource=pods,services`
    
    - Now, whoever this role is assigned to, would get these pemissions automatically

- Now, assign this role to a user `John` - `kubectl create rolebinding developer-binding --role=developer --user=john`
    - This role can be restricted to a specific namespace `--namespace`
        - `kubectl create rolebinding developer-binding --role=developer --user=john --namespace=dev`

    - This role can be assigned to a particular group as well `--group`
        - `kubectl create rolebinding dev-team-binding --role=developer --group=dev-team`

    - This role cane be assigned to a service account as well `--serviveaccount`
        - `kubectl create rolebinding my-app-sa-binding --role=developer --serviceaccount=default:my-svcAccount`

- Now, if `John` is needed to administrate the K8s Cluster, he has to switch the context 

### Logs

- Get Pod Logs: `kubectl logs <pod-name>`

- Get Logs from a Specific Container in a Pod: `kubectl logs <pod-name> -c <container-name>`

- Stream Pod Logs: `kubectl logs -f <pod-name>`

### Policy
- Get Network Policies: `kubectl get networkpolicies`
- Create Nw policy : `kubectl apply -f networkpolicy.yaml`

### Pod Management
- Get all pods : `kubectl get pods`
- Get info about one particluar pod : `kubectl describe pod <pod-name>`
- Delete Pod : `kubectl delete pod <pod-name>`
- Create a Pod : `kubectl apply -f pod.yaml`
- Execute command on pod : `kubectl exec -it <pod-name> -- <command>`

### Deployments
- Get the deployments : `kubectl get deployments`
- Describe on deployment : `kubectl describe deployment <deployment-name>`
- Scale Deployment : `kubectl scale deployment <deployment-name> --replicas=<number>`
- Update a deployment : `kubectl set image deployment/<deployment-name> <container-name>=<new-image>`

### ConfigMaps and Secrets
- List the configmap : `kubectl get configmaps`
- Create a configmanp : `kubectl create configmap <configmap-name> --from-literal=<key>=<value>`
- Get secrets : `kubectl get secrets`
- Create secrets : `kubectl create secret generic <secret-name> --from-literal=<key>=<value>`

### Namespaces
- Get namespaces : `kubectl get namespaces`
- Create namespaces: `kubectl create namespace <namespace-name>`
- Delete namespace : `kubectl delete namespace <namespace-name>`

### Node Management
- List nodes : `kubectl get nodes`
- Describe a node : `kubectl describe node <node-name>`

- Cordon a Node (Mark as Unschedulable): `kubectl cordon <node-name>`
    - prevents the Kubernetes scheduler from assigning new pods to that node.
        - Reason can be Node maintenance
        - Reason can be node is running out of resources

- Drain a Node (Evacuate Pods): `kubectl drain <node-name> --ignore-daemonsets`
     - gracefully removing all pods from a node before taking it offline for maintenance,
 upgrades, or other reasons.

- Uncordon a Node (Mark as Schedulable): `kubectl uncordon <node-name>`


### Other important commands
- Apply some configuration : `kubectl apply -f <file.yaml>`
- Delete a resource : `kubectl delete -f <file.yaml>`
- Get Cluster info : `kubectl cluster-info`
- View API Resource : `kubectl api-resources`


