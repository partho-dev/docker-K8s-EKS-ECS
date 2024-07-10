## We will understand more about networking related to Docker and Kubernetes


- When docker was developed to containerise application, they had to deal with the networking as well for the communication of the containers among themselves and to the externel nw.
- So, they came up with a blue print of networking design named `CNM` - `Container network Model`
    This had mainly 3 building blocks
    1. Sandbox - It is an isolated network stack, this has NIC, ports, route tables, dns config.
    2. Endpoint - Its called vEth( virtual Ethernet) which connects the sandbox to endpoints
    3. Network - Its like a virtual switch inside the container
<img width="542" alt="Docker-nw-1" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/9d4167a9-4e0b-4d72-83d7-a1942581917d">

- Once the blueprint is ready, Docker team created a project called `libnetwork` (Its an opensource project) and they impliments the CNM and includes built-in network drivers like bridge, host, overlay and macvlan.
- There are multiple 3rd party vendors like Calico, Weave, and OVN extended the libnetwork project and created plugins which provides mode advanced container networking capabilities
- By default Docker uses their own default networking and their own drivers like bridge, host, none, overlay etc.

## What are the more advanced capabilities 3rd part plugins provides compared to Docker own drivers
- Calico: A highly scalable networking solution.
- Weave: It creates a virtual network that connects Docker containers across multiple hosts.
- OVN (Open Virtual Network): Part of the Open vSwitch project, providing advanced networking features.

## How to install the drivers on Docker
- Everytime we install docker on our laptop, it automatically installs the default Docker network.
- First it creates a default bridge driver and a default virtual switch called `docker0`
- `docker network inspect bridge` // This gives the driver provide name. `default` is for Docker driver

<img width="716" alt="Docker-nw-2" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/09b33aa4-c0f9-4028-8bc3-4cb702d5d54d">

- If we have used 3rd party drivers like Calico, inn the place of driver, we would have got `calico`

## How to use 3rd party vendor like Calico as a driver
1. First need to follow the installation and configuration guidelines from calico website
2. Then we may create a network like this `docker network create --driver calico --ipam-driver calico-ipam calico-net`


## What is CNM & what is CNI
- `CNM` is a standard model for `Docker` containerisation platform which is designed by the Docker team
But, the same model can not be used by the orchastration tool like `Kubernetes` because kubernetes is a platform which supports other containerisation platform like `podman` `CRI-O` and there are many more.
- So, the `CNM` model was not suitable for a `orchastration tool like K8S` 
- The `CNCF` organization came up a standard model called `CNI` (Container network Interface) which is been adopted by orchestrtaion tools like K8S.
- CNI focuses on defining a standard interface between network plugins (ex: Calico overlay plugins) and container runtimes(Ex: Docker)

## To know about the network 
1. For `Docker` - docker network ls
2. For `K8S` - kubectl describe pod <pod-name>

## To know about the cluster overlay network 
- kubectl get pod -o wide
<img width="612" alt="k8s-cluster-IP" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/2a39f79e-30b7-4d1b-b818-924457ae81a2">

- Here, the IP is the POD IP and each pod gets the IP from the cluster network, that is CNI overlay network plugin like calico.
- They provide `private` IP to all the pods in the cluster, it may be on one node or on the other.
- For `AWS EKS` clusters, the overlay network is their own CNI plugin named `Amazon VPC CNI plugin for Kubernetes`

## How the Docker and Kubernetes creates isolation among the container or pods?

**For Docker**

If we want to isolate one container from the other, we create a seperate custom bridge network
- Because we create a seperate bridge nw, it gets different subnet and different gateway
- So, the containers inside that network is isolated from the container on other bridge network.
- This is an isolation method for Docker
<img width="792" alt="Docker-nw-3" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/e930ef77-116d-4dc1-9dd9-ecdc0271e1ab">

<img width="1062" alt="Docker-nw-4" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/aa979b54-e7d4-4395-91bb-1b109d476893">

- Here both the containers get two different IP of different NW, so communication between these two containers are not possible

<img width="981" alt="Docker-nw-5" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/627d76b3-b1ee-4c15-ac4a-57e5def82b3c">


**For Kubernetes**
- Kubernetes does not have the structure to isolate pods based on networking as all the pod gets the IP on the same network on the CNI plugin IP range.
- So, to isolate that, the way is to create `network policy` 
- Apply the network policy - `kubectl apply -f network-policy.yaml`

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-specific
  namespace: default // Define the namespace where the pod is
spec:
  podSelector:
    matchLabels:
      app: my-isolates-app //This is the app which needs to be isolated
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: allowed-app
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: allowed-app
```

- Apply the network policy `kubectl apply -f networkpolicy.yaml`
- Check if the policy applied corretly 
- We can describe the networkpolicy resource as well
<img width="592" alt="k8s-nw-policy" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/7fa1d38b-733e-41c3-9ec6-1a9f4c6e8f87">

- Find the pods IP address - `kubectl get pods -o wide`
```
macbook@MacBooks-MacBook-Pro docker-K8s-EKS-ECS % kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
express-deployment-6fcdcfd77d-zv4cq    1/1     Running   0          3h18m   10.244.0.6   minikube   <none>           <none>
isolated-deployment-6f4f8ddddf-b9wmj   1/1     Running   0          3h18m   10.244.0.7   minikube   <none>           <none>
```

- Now, go inside the other container and try to ping the isolated pod IP [ ping 10.244.0.7]
- `kubectl exec -it express-deployment-6fcdcfd77d-zv4cq -- /bin/sh`
  - ping 10.244.0.7 // The traffic would not passby
