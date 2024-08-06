## What is K8s and Why do we need K8s
* From the `https://kubernetes.io/docs/concepts/overview/` - Kubernetes is a portable, extensible, open source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation.
* Kubernetes is a software that opensourced by Google which provides the facility to manage maintain one or many containers.
* When we have containers, we need an orchestration mechanisom to take care of the container lifecycle 
    - create
    - run
    - stop
    - pause
    - destroy
    - delete
* The application need to have some communication among themselves and they should also be exposed to the external network.
* The application needs to be highly scalable, there should be load balancing, self healing capabilities
* These all are the features the Kubernetes provides to the containers
* All these complex and automated management to the containers could have been difficult with shell script or some other script, so that is why the Kubernetes are needed.


## Kubernetes in details

![K8s-Arch-1](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/3be733d4-470c-46c8-b8ba-46289fced10e)

![K8s-arch-2](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/b1bb3aa1-65e7-45d0-9448-ce656fe9dafa)

1. Its an open source container management tool
2. Kubernetes control plain - Its like a manager who is controlling or managing all the employees or the containers
3. Data Plane - The platform where all the containers are running 
4. Worker Node : All that(employees) are being managed by the manager 
    - PODS - This is the smallest unit of any Kubernetes
    - containers - Containers stay inside the Pods, K8S does not know anything about the containers, but it knows or manages only the Pods.
    - Kubelet - It is a special agent which is installed on only Worker Node, whose Job is to receives and sends request about the Node requirement to API Server on the Master Node.  It is responsible for PODS.
    - Kubeproxy - This is the entity who takes care of the networking of the Pods of Worker Node. This is responsible to expose the Pods to the internet also
    - Kubeproxy also decides which request to go to which pods.

5. Master Node : This is the main control plane who manages or controls the Worker Node which contains the PODS
    -  API Server -- > The most important components of the Master Node, which is the only source of connecting the two nodes [Master & Worker] Or the single connectivity of multiple components inside the K8S Clusters.
    - Control Manager -- > It checks the state of the containers and compares that with its Active State with its Desired state. [ Active State === Desired State ] 
    - Scheduler -- > It schedules the Pods, ex: Which pods to be killed, which one to be scaled up etc. It takes action on the Pods.
    - ETCD -- > Its a Database which stores the Metadata information of the K8S in Key - Value format.
    - Kubectl -- > Its a Command Line Tool, which is being used by the Admins to take any action on the Pods, they use this tool.

6. Flow Understanding : 
	- Any components inside the K8S cluster to communicate among themselves, they can not communicate directly, they have to communicate through the API-Server. 
	- Ex: If Control Manager wants to communicate with Scheduler, it can not directly communicate, it needs to pass its information through API-Server.

## Lets understand the involvement of each components with a real requirement 
**Problem Statement** - One Web Application is running and it is using only 1 POD, we got to know that the traffic is going to increase and so we need 100 PODS now, Let see how this happens and see its complete flow.

**The Flow** 
   -  The request of increasing the PODS is first received by the agent Kubelet on worker Node
   -  Kubelet sends that data to API-Server on the Master Node
   ![image](https://github.com/user-attachments/assets/fb666611-ff49-4377-9516-2e12cf7ee948)
    - Image taken from Google
    - API Server is the main door and it checks `3As` 
    - 1st A - `Authentication` :  The user/programm is authenticated to perform the task(It generally comes through request header)
    - 2nd A - `Authorisation` : Checks if the user is authorised to do the task based on RBAC
    - 3rd A - `Admission Control` : Its a module which modifies or reject the request. & then saves to DB (`ETCD`)
   -  API-Server stores that information into its Database ETCD [ The request does not store to DB directly, it needs to follow the Governance]

- ![k8s-admission-controller](https://github.com/user-attachments/assets/48092a3e-eb63-49e7-bcd5-56d1403401e8)

- **Note**
-  ✅ When a user sends an API using kubectl, the request first has to pass through the gateway API Server and that API server checks if the requested user is authenticated and authorized(RBAC)
-  ✅ If the requested user is authenticated, the request object gets stored in the ETCD Database.
-  ✅ But, before the object gets stored into the DB, the Kubernetes verifies the object and checks for the governance based on custom policy or business logic through Kubernetes Admission Controller.
-  ✅ There are close to 30+ default admission controllers policy are there https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#what-does-each-admission-controller-do

-  ✅ The `Admission controller` has the capability to mutate(change)/change the request and update the object with new properties before its added into ETCD.
Notes : Admission controller does not block any request for GET
Admission controllers limit requests to create, delete, modify objects.



   -  Controller Manager it always watches the resource & get to know about that from the ETCD, Now, it will compare active state with the desired state.
        Actual PODS State = 1
        Desired PODS = 100 
   -  Control manager finds that it needs 99 PODS extra as per the request, so it will store that information into ETCD Database.
   -  Scheduler gets to know about this new request from ETCD through API-Server
   -  Scheduler takes an action and launches the 99 PODS and through Kubelet, these PODS are getting deployed into the Worker Node.
    - Scheduler finds the best node by using the techniques like `taints`, `tolerations`, `affinity`, `nodeselector`
   -  Then Kubelet updates the ETCD database with its current Active state of PODS  

7. The Control plane does not have the capability to control the containers on the worker node. It can manage the POD, & the container stays inside the POD.
8. pod : Its a place where the application image containers can be placed. its advisable to have one container application for one pod, we can have many application per pod, but 1 pod 1 container is suggested.
9. container : The application itself, like Angular container image, Mongo image etc

10. ## PODS | Replicaset | Deployment
    <img width="733" alt="pods|rs|deployments" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/9b8063a1-db69-47aa-ade0-b36ece93723c">

    ![pods-service](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/17d29e24-6b3e-4e07-8aac-a2d2679e5ac9)
**Note** : Deployment is a Kubernetes object
- Pods contain container with some application running, but if the POD dies, the application becomes unavailable and that gives the downtime
- To overcome that limitations of PODS, replicaset was created
- Replicaset creates multiple replica of the same PODS and keep them available to handle the traffic and if the replicaset creates 3 replica pods and 1 pod dies, replicaset has the capability to create another PODS and always maintain 3 PODS, So the downtime is not there on the container applications for the end users.
- But, if there is any update into the source code, this does not get updated to any of the PODS created by the replicaset automatically, for that manually all the pods needs to be terminated and then recreate them. But, in the production there may 100 PODS and its tough to manually terminate all the PODS and then apply the replicaset menifect file.
- To overcome this limitation, its not advisable to use replicaset manifest file, instead we should use deployment manifest file. 
- Deployment manifest provides the facility to create the Replicas of PODS and the update the PODS with latest version of the container image with latest source code.

11. When a Pod gets deployed, it automatically receives an IP address(Private IP) from the cluster network, mainly they are the network adapters from 3rd party company like Calico.
12. services : Two pods with two different containers communicates over internal IPs [IP for pods not containers]  of pods, but the IP may change so, the communication of application with DB may be interrupted, if the DB pod dies and a new pod comes with new IP and it becomes unreachable with the old IP, so to get rid of this IP dependancies on Pods,  a component called “service” gets attached with pods and then the communication between two container is possible through a service name (svc) of service

    - ex: http://cart_deployment.svc:8080
    - It also acts as a Load Balancer (based on the service mode - cluster mode, nodeport mode, Load Balancer Mode),
    - which directs the traffic to different pods of same name space of 2nd replica
    - But, the problem still remains the same, the ontainer gets a new IP, so how a service able to communicate with the application container which gets new IP.
    - This becomes possible for service because of service discovery, here it does not track the containers based on its IP address, but it tracks based on labels and selectors.
    - service enables the containers to be accessible from other networks
    - It has 3 different modes to set up the containers
        - cluster mode - makes the container accessible from within the container only 
            - Login to minikube and can be accessible
        - nodeport mode - makes the container accessible from the node
            - Access from the host 
        - Load Balancer mode [available only for cloud K8S setup]
            - It provides a load balancer public IP, so its accessible anywhere But, its expensive, as each service needs seperate LB, so cost of cloud increases
            - It provides only Round Robin LB capabilities
            - Other LB capabilities like sticky session, host/path based rounting are missing Does not provide any TLS out of the box

    - Service in K8S filled the gap of losing the connectivity with pod because of new IP assigned to the newly created pod, while the previous pods gets terminated. Pods are ephemeral in nature.
    - It even provided the facility to connect from external network using service type as Load balancer and it equally distributes the traffic among other pods.But, this had some limitations.
        1. 	Exhausted requirement of Load balancer static IP for each service
        2. 	There were no security(TLS) on the traffic of request and response
        3. 	The Load balancer type does not provide the other benefits like
            - Host based routing
            - Path based routing
            - Maintaining session to one particular pod
    - Ingress gives the solution to all these limitations of K8s service.
    But, ingress also has some limitations, like it does not provide the health check of the pod, for that we have to rely on Liveness Probe & Readiness Probe.
    - So, its always recommended to create the deployment manifest file as a common file for both deployment and service.

## Developer Flow 

1. 	Do the development of the application
2. 	Create a Dockerfile for that application
Create an image of the application from the base image mentioned on the Dockerfile
Run a container from that image – use volume flag to keep the container updated.
3. 	Push the container on Dockerhub
Deploy in k8s [Into K8S Cloud ] [Or local for testing ]
Need to write K8s deployment configuration files. (yaml file)
Write configuration for Deployments
4. 	The deployment is responsible to creating the number of pods. Once the pods are created, the images are pulled from dockerhub and spin the containers
5. Enable communication of the pods-containers within the cluster | For that, configure cluster-IP service
Write the pod deployment files.

Need to write the deployment files separately for all the applications or microservices.
For an example, there are two microservices cart and products, so need to write two deployment files for cart and products.
 
To write the deployment files, execute this command
- `Kubectl create deployment (or deploy) product --image=daspratha/product –dry-run -o yml  > product-deployment.yml`
<img width="1110" alt="Docker-0" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/653b4c4c-a834-4987-897a-a0830a4ab7aa">

- after updating the same yml file, to run that again to create the new IP service, execute this command
First time : k create -f product-deployment.yml  [ -f = from the file or kubectl instead of k]
After any changes : kubectl apply -f angular_deployment.yaml

- **Note**: Only two objects are created on this k8s. Deployment and services.
There are other advanced objects also there node selector, node affinity, network policy etc.

## What is network policy in K8S : 
- Network policy is one of the Kubernetes resources that governs the ingress(incoming) & egress(outgoing) traffic to and from a pod.
- We can compare that with AWS Security group which governs the traffic flow to the Ec2 by defining the incoming rule for port and the destination from where it can be accessible. 
- Network policy for K8S : When we assign a network policy to a pod.
    - This conntrolls traffic @ the pod level within a cluster, 
    - We can define what kind of traffic is allowes and which pods can communicate
    - It is applied at finer granularity, such as specif pods within a namespace

### Eample of network policy 
<img width="804" alt="nw-policy-k8s" src="https://github.com/user-attachments/assets/43e8bd93-8abf-4948-8da4-1f858b27d669">

### To see all the pods and services inside the Kubernetes cluster, execute this command : 
`k get all  [ kubectl get all ]`

![k8s-1](https://github.com/user-attachments/assets/70df2de9-1a95-4619-932c-0b80623570ad)

6. External service : To make the application accessible through browser,  
    - for that we need to create an external service.
    - ex: `http://my-app-public-ip:8080` | 
        - `http://server-ip-of-node:service-port`
- Its good only for test & Development

7. Internal service : But the DB pod should not be accessible from outside, 
    - for that internal service is needed.
    - `ex: http://db-service-ip:27017`
8. Ingress : In real world we cant communicate with `http://190.165.1.100:8080`, 
    - we need `ssl` with domain and that is made possible by ingress. 
    - Which makes the application url `https://my-app.com`

### Flow 
* Request comes to ingress > Forwards to service
* But, for that an ingress controller pod needs to be created, 
    - which checks all the incoming traffic and forwards to the correct services.
* Afte the controller is installed, need to create the ingress rule
* There is something called default backend, which needs to be configured to rediect all error pages

![k8s-2](https://github.com/user-attachments/assets/d2e381db-72ed-426c-896c-4c058b980cb1)

* Ingress resource, overcomes the gap of Load balanncing capabilities of that service provides.
* But, even “ingress” misses the most important check of the container on the pod.
* For that K8s has to again rely on `Readiness` & `Liveness probe` 
    -  it helps to ensure that the application on the container is running correctly and can respond to traffic appropriately.
* `Liveness Probe` - It determines if the container is `runninng` 
    - If a liveness probe fails, Kubernetes will kill the container and, depending on the restart policy, may restart it
* `Readiness probe` - It determines if the container is `Ready` to accept any traffic.
    - If a readiness probe fails, Kubernetes will remove the pod from the list of endpoints for a service, ensuring that no traffic is sent to it until the readiness probe passes.

- <img width="795" alt="k8s-3" src="https://github.com/user-attachments/assets/e5b5fb2a-b0a4-4f37-a8ee-bbedfe88f5e2">

- <img width="799" alt="k8s-4" src="https://github.com/user-attachments/assets/aeec5ac9-ed9f-4208-a28b-3f6065ff241d">
- <img width="793" alt="k8s-5" src="https://github.com/user-attachments/assets/e6064cb9-b990-4369-aefa-4bafc8df3c8a">

## Why we need Config Map
9. `Configmap`

**Understand the problem**
- If there is any changes in any application base url `ex: DB base url` changed, so we have to update that into the application and then run the build, create image and then put into pod and its a long process.

- rather updating tha base url  or any other environment variable into configmap.
- It is mapped with the pod
- this has its own configuration.yaml file

## Why do we need Secret

`secret` 

**Understand the problem**
- There are some variables like db user_name & Pass, which is not secure to put in configmap in plain text

**Solution**
- so its kept into secret.
- Secrets are kept in `base64 encoded` | Connect with pod
- `echo -n 'your_username' | base64  `
- Note : Its good practise to use custom encryption because its easy to decode any base64 encrypted items
Your DB_Pass is “Password123” 
- This gets encrypted in secrets file automatically using base64 encryption
- If we go to secret file, we can see the password might look like this `UGFzc3dvcmQxMjM=`
- This seems impossible to `decrypt`, but its really easy by executing a command as below
- If we go to any Linux terminal and type this `“echo UGFzc3dvcmQxMjM= | base64 --decode”`
- So, any hacker who gets access to the deployment yaml, or kubectl 
- By executing this command they can get to know the secret files content kubectl edit secret secret_name

### secret has its own yaml deployment file 
- This configuration file needs to be applied first before applying the deployment yaml file


`Volumes` : Or data storage 
-  persistent data of any DB container, 
- pod is very important for any application, 
- but as the pods are ephemeral
- so to maintain the consistency in data, volume is used.
- It is an external hard disk, ssd connected to k8s cluster 

`Deployment` : 
- Its a blueprint for deployment of pods and its replica
- We never creates pods, we as a devops eng creates deployments
- We cant replicate a DB pods using deployment, because DB has a state.
- We use deployment for stateLess apps

`Sateful Set` : 
- This are made specifically for Databases which has states or need a consistent data source.
- We use statefulset for stateFull Apps or databases.
- As DB are little difficult to create using stateful set, 
- so DB are often hosted outside of K8s cluster

### Custom Resource(CR), Custom Resource Defination(CRD), Custom Controller:

- Kubernetes already has many resources like `ingress` and `ingress controller`, 
- but to extend the capability of K8S which needs some customisation, 
- we can develop own `custom resource` and its `custom resource defination` to validate the custom resource.
- The most common programming language that can be used to develop the custom resource & defination along with controller is `Go` programming language.
- The custom resource can extennds the capability of K8s API.
- Kubernetes Custom Resource (`CR`) : 

    - Some application deployed in K8S cluster may need some additional support or additional need which is not natively available with K8S resource like pods, deployment etc, in that case, we need to develop the custom resource.

- Custom Resource Definition (`CRD`) :  
    - Every Kubernetes resource need to follow some `guidelines` that is defined for that resource and that is defined by that resource defination, 
    - for native K8S resource, these definations are already exist in the K8s cluster. 
    - But, when we develop a new resource, that also need to follow some guidelines and that is defined in cluster defination.

- `Custom Controller` : 
    - Like K8S COntroller, which always keeps an eye(watch) on the resource thrugh K8S API and takes any action to ensure the desired state matches with the current state, 
    - the build in controller would not be able to monitor the cutom resource, so a custom controller is needed to watch that. 

### How to impliment the Custom Resource
- To impliment the custom controller, 
- we use K8S operator framework. 

***Lets see how that works***

- `watch` - The controller keep an watch to identify if there is any change in custom resource.
- `Reconcile` - It is a function which takes the change on resource state as a parameter and it compares that with the desired state. If it finds any channges, it takes an action to keep the state aligned.
- `Act` : Based on the channge, the controller perform action such as CRUD of the resource.

### Develop a custom COntroller

- To develop a custom controller, 
- we can use `Go lang` or `Python`, 
- since K8S is nnatively developed using `Go`, so most of the DevOps eng prefer to use `Go` Lang.
- To communicate with K8S API, we have to communicate with `GoClient` first,
 - to see `any changes` in the custom resources, 
 - we have to create our own `custom watchers` as well, 
- there are `frameworks` like `“Kubernetes controller runtime”` which is a set of libraries to build kubernetes controllers.
- So, when the watcher finds any chage like CRUD of resource, it communicates with `GoClient(reflector - a component of GoClient)`
- Once we develop a custom controller, 
- to install that controller into K8S and mannage its lifecycle, 
- we can use K8S operators. `https://operatorhub.io/`

![argo](https://github.com/user-attachments/assets/712ffee0-064c-4e92-9519-b96a95d7bb1b)

### How to install Custom controller on k8s Cluster

- To install the custom controller on K8S cluster 
- `minikube` for local laptop of `EKS` for AWS etc
- `First` install the `OLM` on the cluster [Operator lifecycle manager]
- Now install the operators 
    - Example of installing ArgoCD operator into K8S cluster using operatorshub.io
- Once the operator is installed, we have to do the installation of controller 
- follow this for ArgoCD - https://argocd-operator.readthedocs.io/en/latest/usage/basics/


### What is K8S API and how can that be accessible using CURL or Postman

- The K8S API is not same as Express API which included req and res object, but this is same as any other RESRFul API.
- It follows the same HTTP Method like `GET`, `POST`, `DELETE` etc

**Overview of API of K8s**

- we need K8S API to connect with K8S cluster and perform CRUD on K8S resources
- It has different end points which is exposed to perform CRUD on K8S Resources
- To access K8S API, authentication is needed through Token mechanism & Authorisation policies.

***Some example of K8S API Endpoints***

- Read all Pods in certain namespace : `GET /api/v1/namespaces/{name_namespace}/pods`
- access using CURL : `curl -k -H "Authorization: Bearer <token>" \      https://<k8s-api-server>:6443/api/v1/namespaces/default/pods` 
- Read one particular pods : `GET /api/v1/namespaces/{namespace}/pods/{pod_name}`
- Create a deployment : `POST /apis/apps/v1/namespaces/{namespace}/deployments`
- Delete a pod : `DELETE /api/v1/namespaces/{namespace}/pods/{pod_name}`

### How to access the API using Postman: 
- We would need to get the Token which has to be used for authorisation headers tab on Postman.

### How to get the bearer Token? 🤔🤔🤔 : 
- Use kubectl : `kubectl config view --raw `
- This will provide information of token under user section

## Kubernetes Governance and rules set by the organization. (Admission COntroller)

- We have AWS Config to set some specific rules for AWS resources to comply, 
- similar to that, there should be some governance for K8s clusters resources like Pods, namespace that should be followed to meet the organization standard procedure. 
- As all the traffic into Cluster go through API Gateway, 
- so if we have a mechanism to be applied on that level to validate the resources, 
- it becomes easier to maintain the governance on K8s.

**Solution**

✅  This problem was solved by `Admission controllers`, 

❌ but it has a ***limitations***

- It becomes a devOps engineer responsibility to write the Admission controllers using Go programming language.
- For each policy a new Admission controllers need to be written and it becomes unmanagible if the number of policies grows or if it needs any modification with time.

✅  So, to solve the problem of managing the policies or rules through custom Admission controller, 
- the tools like `Kyverno` policy engine is used

- 💡 Admission Controllers are `built-in components` (Not a Custom Controller) of the Kubernetes API server that intercept API requests before they are persisted to the underlying storage. 
- 💡 They can be used to enforce policies on objects during their creation, modification, or deletion. 
- 💡 Admission controllers are not custom controllers; they are a core part of Kubernetes and can be enabled or disabled through the Kubernetes API server configuration.

***Types of Admission Controllers***

- ✅ `Mutating Admission Controllers`: Modify the incoming requests to ensure they adhere to specific policies.
- ✅ `Validating Admission Controllers`: Validate the incoming requests against certain rules and reject them if they don't comply.

    - Some `**commonly used**` built-in admission controllers include `PodSecurityPolicy`, `ResourceQuota`, `LimitRanger`, and `NamespaceLifecycle`.

- ✅ `Custom Policy Engines`: 

**Kyverno vs Built-in Admission Controllers**

- ✅ `Kyverno` is a `Kubernetes-native policy engine` designed to provide more flexible and powerful policy enforcement compared to the built-in admission controllers. 
- ✅ Here are some benefits and features that Kyverno offers:

**Benefits of Using Kyverno**

- ✅ `Kubernetes-Native`:
Kyverno uses Kubernetes Custom Resource Definitions (CRDs) to define policies, making it intuitive for Kubernetes users to understand and apply.
- ✅ `Policy as Code`:
- Policies are defined as Kubernetes resources, which allows to manage them using standard Kubernetes tooling (e.g., kubectl, GitOps workflows).

- ✅ `Validation, Mutation, and Generation`:
- `Validation`: Ensure resources conform to specified rules (e.g., all pods must have resource limits).
- `Mutation`: Automatically modify incoming resources to match policies (e.g., add labels, set default values).
- `Generation`: Automatically create resources based on existing ones (e.g., create ConfigMaps from ConfigMap templates).
- `Ease of Use`:
    - Kyverno policies are written in YAML, which is straightforward for Kubernetes users. 
    - There's no need to learn a new language.
- `Granular Control`:
    - Kyverno allows for detailed and specific policy definitions, 
    - making it possible to cover more complex scenarios than built-in admission controllers.
- `Built-in Policy Library`:
    - Kyverno provides a library of pre-defined policies that you can use out-of-the-box, 
    - which can significantly speed up policy enforcement setup.
- Example Kyverno Policy
    - Here's an example of a Kyverno policy that validates that all pods have resource requests and limits defined:

<img width="794" alt="Gov-k8s" src="https://github.com/user-attachments/assets/ce88500f-538e-4a2e-9bb2-e19f338f59fc">

### Implementing Kyverno in a Kubernetes Cluster
- ✅ Install Kyverno:
- ✅ Install Kyverno in your cluster using the provided manifests or Helm charts.
- ✅ kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/definitions/release/install.yaml
- ✅ Define policy:
- ✅ Write your policies in YAML and apply them to your cluster.
- ✅ kubectl apply -f require-requests-limits.yaml
- ✅ Monitor and Manage:
- ✅ Use kubectl and other Kubernetes tools to monitor and manage your policies.



## ====== kubectl commands ======

### CRUD commands using kubectl | This happens only at the Deployment level

- Create deployment (C) : `kubectl create deployment [deployment_name]`
- Read deployment (R) : `kubectl get deployments`
- Edit deployment (U)	: `kubectl edit deployment [deployment_name]`
- Delete deployment 	: `kubectl delete deployment [name]`

### Status of different k8s components.
- kubectl **get** `nodes` | `pods` | `services` | `replicaset` | `deployment`

### debugging pods
- Log to console 		: `kubectl logs [pod_name]`
- Get interactive terminal 	: `kubectl exec -it [pod_name] -- bin/bash`

### Why there is no command to create pods 
- we can not create pods, 
- it has to be created by its obstructed tool called deployment

### Layers of abstraction
- Deployment manages a Replicaset
- Replicaset manages a pod
- Pod is an abstraction of Container
- Anything post deployments are managed by k8s.


### Create deployment 
    - `kubectl create deployment [deployment_name]`
- The above command creates the deployment based on the arguments passed on the command line, 
- ex: `Name`, `image name`, `replicaset` etc.
- To make it more easier, its better to write own k8s configuration file and mention all the options there.
- but to get all these applied into deployment, execute the command
- `kubectl apply -f k8s_confg_file.yml`
 
### CRUD for configuration file
- Apply a configuration file 			: `kubectl apply -f file.yml`
- Delete  with configuration file 		: `kubectl delete -f file.yml`

## ==== K8s configuration file - yml====
 - syntax of the k8s configuration file [ deployment.yaml | service.yaml | secret.yaml]

<img width="794" alt="k8s-dep" src="https://github.com/user-attachments/assets/5692fcb5-5fef-4809-8e4f-61e0a5c122fa">


## Kubernetes Namespace
- In Kubernetes the resources can be organised in namespaces.
- Its like a virtual cluster inside a K8s cluster
- By default the K8s gives 4 namespaces when we create K8s clusters
- `kubectl get namespace`
    - Kube-system : It for system use, we should not create/modify this namespace
    - Kube-public : It contains the publicly accessible data,
        - Its a config map which contains cluster information
- `kubectl cluster-info` : 
    - This output info comes from this namespace
        - `kube-node-lease` : It contains the info about the heartbeat of each node
        - `default` : This namespaces is used to create the resources at the beginning, until a new namespace is created by you.

### How to create new namespaces:	
- `kubectl create namespace my-namespace-name`

### Why we use & what is the purpose of namespaces : 
- When we create resources like pods, containers, services etc all goes into default namespaces 
- and over a period of time for complex app, it becomes hard to `manage`.
- so, the best practices is to have separate namepaces as per the application requirements and group them all together.
- Ex: Database namespace can hold all the resources associated with database, same for monitoring etc

<img width="792" alt="k8s" src="https://github.com/user-attachments/assets/87c3c93f-2d79-4ebc-8e26-b6faa618dfea">

### Characteristic of namespaces
- We cant access most resources from another namespace.
- Access services in another Namespaces
    - Ex: Here, the application server on `Project-A` namespace wants to connect to the DB resource on `Database namespace`. 
    - so, in the configuration file, it is mentioned as 
    - resource_name.Namespace_name
    - mysql-services.database

- ![1](https://github.com/user-attachments/assets/24bb0053-50e7-4f89-8a90-627b3ef8db13)

### Wht are the Components, which cant be created within a namespace.
- Live globally in a cluster
- Cant isolate in any namespace
    - ex: Volume & Node
    - ![2](https://github.com/user-attachments/assets/1e8e1d45-43e4-4693-895b-130854634672)

### To know which resources are not a part of any namespace 
- `kubectl api-resources --namespaced=false`
- `kubectl api-resources --namespaced=true`


### How to associate a config file to a certain namespace
- `kubectl apply -f config.yaml --namespace=my-namespace-name`
- Another way is to have the name space name inside the config file itself

![3](https://github.com/user-attachments/assets/6e75bb9b-61d2-4d83-bcc9-fb511efffc2a)

### Some useful k8s commands

1. Scale up to 3 replicas: `kubectl scale deployment node-app --replicas 3`
2. Get to know more details about a node: `kubectl get nodes -o wide`
3. Enable Load Balancer to the service
4. Edit the service: `kubectl edit service node-app`
    - Replace port: 3000 with port: 80
    - Replace type: NodePort with type: LoadBalancer
5. Verify that the service was updated: `kubectl get service`
6. To update any changes on the manifest(deployment) file : `kubectl apply -f deployment.yml`
7. To Delete a Pod 
    - Know the pods status : `kubectl get pods`
    - pods get auto healed and created again if you delete using this command - `kubectl delete pods “podname”`
    - know the name of namespace - `kubectl get rs --all-namespaces `
    - find the name of deployment from the deployment file under deployment metadata
    - Execute this command to delete the pods - `kubectl delete deployment angular-myapp --namespace default`
8. To delete the services:
    - Find the list of kubernetes services : `kubectl get svc --all-namespaces -o wide`
    - Describe service to know its purpose : `kubectl describe svc angular-service --namespace=default`
    - Delete the service : `kubectl delete svc --namespace=default angular-service `

## Helm Explained:

### What is helm?
- Its a package manage fro K8S, Ex - npm fro node, apt fo ubuntu etc
- It is used to package YAML friles and distribute them in public and pirate repositories.

### What ae helm chats?
- Ex: To Deploy a Data base like `MongoDB`, 
- we would need many yaml configuration file, 
    - ex: Secret yaml file, to maintain the password or the DB
    - config map, stateful set etc. to keep the DB Endpoint and username or port info.
- Its difficult to write them by remembering each component, 
- so these configurations are already been made and available as a `bundle` in `helm repositories` by some contributor, 
- which can be downloaded and used. 
- This are known as `Helm charts` 🔥🔥🔥🔥🔥 .

- 👨‍💻 👨‍💻 👨‍💻 For  some deployment of any kind of application, you can search fro the helm chat 
    - `helm seach <keywod>`
- How to use them?
- When to use them?
- What is Tiller?

- Why we need Helm charts for Kubernetes

- Let's say we need to deploy a `WordPress` on K8s. 
- So, lets see what are some of the components of a WordPress?

    - It needs a `web server` with `nginx` or `apache` and a `database` server for sure, 
    - and for high availability we would need that nginx to run on 3 different pods
    - Likewise, for the database, MySQL is three different pods. 
    - then we will have a service in front of the database and another service in front of the webserver.

- Now, to impliment these all yaml configuration on K8s. 
- we will need to create many different `manifest` files (yml) for different components, 
- and maintaining all these files is a nightmare. 
- So `Helm` solves this problem by giving the ability to run this WordPress solution in one package with just one simple command.

- Helm makes it easy to deploy faster than ever. With the recent Helm 3, there has been a lot of improvement.

- Helm gives a better way to deploy a `multi-component `Kubernetes workload than doing it directly working with the native objects piece-by-piece. 
- When you want to think about operationalizing on Kubernetes, Helm is one tool you want in your toolbox.

![helm](https://github.com/user-attachments/assets/2eaa4c8d-d703-4bfc-84b2-6e9ead881670)

