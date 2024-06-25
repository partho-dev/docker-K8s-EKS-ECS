## We will understand more about networking related to Docker and Kubernetes


- When docker was developed to containerise application, they had to deal with the networking as well for the communication of the containers among themselves and to the externet nw.
- So, they came up with a blue print of networking design named `CNM` - `Container network Model`
    This had mainly 3 building blocks
    1. Sandbox - It is an isolated network stack, this has NIC, ports, route tables, dns config.
    2. Endpoint - Its called vEth( virtual Ethernet) which connects the sandbox to endpoints
    3. Network - Its like a virtual switch inside the container
<img width="542" alt="Docker-nw-1" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/9d4167a9-4e0b-4d72-83d7-a1942581917d">

- Once the blueprint is ready, Docker team created a project called `libnetwork` (Its an opensource project) and they implements the CNM and includes built-in network drivers like bridge, host, overlay, and macvlan.
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

