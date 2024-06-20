# Local Kubernetes cluster on Mac

* To do the test on one laptop, its not possible to setup the production ready K8s configuration with 2 master node & 3 worker nodes. 
* To reciprocate that, we use `Minikube` on our local laptop.

* To communicate with the cluster through API server, we need a CLI and thats kubectl.
* By default, minikube uses `Docker driver`, but, this networking has some limitations.
* Its always good to start miniKube using `hyperkit` driver. 

- Install miniKube on mac : `brew install minikube`
- check the status : `minikube status`
![minikube-status](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/00679f02-c526-43c6-b834-045424d94a58)

- Command to start the miniKube `minikube start`  *Default starts with docker driver*
![minikube-start](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/5f6cb5a1-94ef-422e-b891-0bf7ee17dc98)

- Check the minikube status - `minikube status`
- Know which driver minikube is using - `minikube profile list`
![minikube-profile](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/2b655acc-b6a3-4cc2-93f7-f4ef34f109e6)

- To start the cluster with hyperkit driver : Hyperkit is more lightweight than docker driver for mac. `minikube start --memory=4098 --driver=hyperkit`
    - for that hyperkit needs to be installed - `brew install hyperkit`

- Now to communicate with K8S cluster, install kubectl `brew install kubectl`


