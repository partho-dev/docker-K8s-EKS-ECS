## what is docker
Docker is a software or a container runtime, which can be installed over any operating system like windows, linux or mac.
There are many questions now?
 - software?
    * Yes, its a software which extends the capability of the underlying host machine.
- container runtime?
    * Yes, container is like an individual application running on the same host, but it isolates itself from the others.

## What benifits Docker provides and who the docker is for?
- Docker is mainly used for application developed by the developers, which helps developers
 * Automate the deployment
 * Manage, scale, ship the application using lightweight containers

## What are the key components that one need to remember
 * `Container` - Its a standalone packages that can be used to run any application. This includes the OS, the necessary libraries, packages for the application and the application code.
 * `image` - When we talk about standalone container which is the actuall application, that can be kept in a repository or share with other collaborators as an image. 
* `Dockerfile` - The reason the docker is widely used and it is easy for anyone to use because of its declaritive way of creation of image using some instructions and that instructions are written in that Dockerfile.
* `Docker Hub` : GitHub is a version control system for source code, similarly, Docker Hub is also used as a VCS for docker images, from where we can pull the lightweight image that we want and make use for building a container
    
**So, is it not same as VM that we had previously**
- It is similar to VM, but not same, VM provided a layer of virtualisation over the host OS.
- With that virtualisation, we can create another server with its own OS and libraries and over that we can have our software application running.
- This was good, but it had the limitation as it shares the Host resources like CPU, RAM and if the application running on that VM hardly uses 20% of that VM resources, there were no much ways to dynamically reuse the resources, 
- though there were some mechanism to create a VM which consumes the resources based on the requirement.

## Why do we need docker

- Thats where the concept of Docker came, which allows to create an application with its own dependancies over the host OS and bundle that as a single entity.
- This does not create any OS, rather it uses its own lighweight OS and build the application over it and combinely call it a conntainer.
- Now that container can run on any other Host which has Docker installed. 

# Evolution of Docker as a container 

![docker-evolution](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/5c150721-a247-4f60-ab30-2d03fc355e9f)

## Docker is very strong because of its networkinng as well 
- The moment we install docker on our local laptop, it **automatically** creates a virtual network called `docker0`
- It acts as a virtual bridge between the Host OS Network interface and the containers to communicate among themselves.
![image](https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/a9706cf4-7cb4-4b71-96db-c905a9700d72)

- During container creation & start, if no specific network is defined, then by default docker attach the container with `docker0` network
- Docker uses `NAT` - Network Address Translation for containners to access & communicate with external network, Port mapping is also possible.

