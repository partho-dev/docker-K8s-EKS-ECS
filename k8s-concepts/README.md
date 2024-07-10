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
   -  API-Server stores that information into its Database ETCD
   -  Controller Manager it always watches the resource & get to know about that from the ETCD, Now, it will compare active state with the desired state.
        Actual PODS State = 1
        Desired PODS = 100 
   -  Control manager finds that it needs 99 PODS extra as per the request, so it will store that information into ETCD Database.
   -  Scheduler gets to know about this new request from ETCD through API-Server
   -  Scheduler takes an action and launches the 99 PODS and through Kubelet, these PODS are getting deployed into the Worker Node.
   -  Then Kubelet updates the ETCD database with its current Active state of PODS  

7. The Control plane does not have the capability to control the containers on the worker node. It can manage the POD, & the container stays inside the POD.
8. pod : Its a place where the application image containers can be placed. its advisable to have one container application for one pod, we can have many application per pod, but 1 pod 1 container is suggested.
9. container : The application itself, like Angular container image, Mongo image etc

10. ## PODS | Replicaset | Deployment
    <img width="733" alt="pods|rs|deployments" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/9b8063a1-db69-47aa-ade0-b36ece93723c">

    ![pods-service](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/17d29e24-6b3e-4e07-8aac-a2d2679e5ac9)

    1. Pods contain container with some application running, but if the POD dies, the application becomes unavailable and that gives the downtime
    2. To overcome that limitations of PODS, replicaset was created
    3. Replicaset creates multiple replica of the same PODS and keep them available to handle the traffic and if the replicaset creates 3 replica pods and 1 pod dies, replicaset has the capability to create another PODS and always maintain 3 PODS, So the downtime is not there on the container applications for the end users.
    4. But, if there is any update into the source code, this does not get updated to any of the PODS created by the replicaset automatically, for that manually all the pods needs to be terminated and then recreate them. But, in the production there may 100 PODS and its tough to manually terminate all the PODS and then apply the replicaset menifect file.
    5. To overcome this limitation, its not advisable to use replicaset manifest file, instead we should use deployment manifest file. 
    Deployment manifest provides the facility to create the Replicas of PODS and the update the PODS with latest version of the container image with latest source code.

11. When a Pod gets deployed, it automatically receives an IP address(Private IP) from the cluster network, mainly they are the network adapters from 3rd party company like Calico.
12. services : Two pods with two different containers communicates over internal IPs [IP for pods not containers]  of pods, but the IP may change so, the communication of application with DB may be interrupted, if the DB pod dies and a new pod comes with new IP, so a component called “service” gets attached with pods and then the communication between two container is possible through a service name (svc) of service
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

