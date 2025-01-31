## Kubernetes cluster is created, Now, how to deploy pods and launch applications on the cluster

- Make sure minikube is installed on system
    - `minikube version`

- Start the minikube 
    - ensure `hyperkit` is installed
    - `minikube start --memory=4098 --driver=hyperkit`

- To communicate with Kubernetes clucter(Minikube) - Need `kubectl`
    - check if kubectl is installed `kubectl version`

- Once the minikube is started, know the information about the **cluster**
    - `kubectl cluster-info`
    - `kubectl config view`

- In the cluster, we will have one or many **nodes**, to know about that.
    - `kubectl get nodes`
    - Get the **STATUS** of node as `Ready ` or `NotReady`

- What is inside the nodes - **Deployment** & **pods**, Check that 
    - `kubectl get deployment`
    - `kubectl get pods`
    * If it says nothing found on **DEFAULT** namespace, that means we need to create them
    - Get the resource on **other** namespaces 
        - `kubectl get deployment --all-namespaces` 
        - `kubectl get pods -A` === `kubectl get pods --all-namespaces
        - This would provide some system resource deployments on dofferent namespaces

- To communicate with the nodes or pods, we would need to have `services`
    - Check the services `kubectl get services` 0r `kubectl get svc` Note: There may be one **default** `kubernetes` service

- Now, write the Kubernetes menifest files

1. `Deployment.yaml`
- There are two ways we can create the deployment

## Automatically using `kubectl create` command

- use `kubectl create` command to create that automatically
- I suggest to create that using `create` command and read the file and then manually do some edits and see the output.
- Once it gets a practice, we can write that manually 
* `kubectl create deployment express-deployment --image=daspratha/express:v1`

**OR**

2. Manually - create a file `Deployment.yaml` & write all the configurations manually
        
**Service**: The applications are inside POD and POD gets cluster private IP, so to get the pods exposed to NodePort(Host Nw), create a service

- Create the service using `kubectl expose` command
- Know the deployment name - `kubectl get deployment`
- expose the deployment with nodeport type 
    - `kubectl expose deployment express-deployment --type=NodePort --port=3000`
    - check the service - `kubectl get svc`

* - The source code does, src or Dockerfile may not be needed to be on the same place.

- Once the service is deployed, check its URL to access the pod 
- Know the service name - `kubectl get svc`
- `minikube service express-deployment --url` #http://192.168.64.2:31683

-  Now, go to browser and you will see the application from this URL
- Once the deployment & service are created, to **delete** them
        - **Deployment** - `kubectl delete deployment express-deployment`
        - **Service** - `kubectl delete services express-deployment` 

### How to see the minikube dashboard 
- once all the pods are deployes, to vidualise that through GUI, we need a dashboard
- Minikube provides the dashboard - `minikube dashboard`

- <img width="1052" alt="dashboard-1" src="https://github.com/user-attachments/assets/54d5f653-5830-45f7-8f5a-c7e59d441fd7">

- <img width="1663" alt="dashboard-2" src="https://github.com/user-attachments/assets/c6cea51a-f7ce-4018-b1fe-5a59f4517eb5">