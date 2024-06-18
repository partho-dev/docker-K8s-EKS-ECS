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
- `docker0` provides a default IP range in this subnet `172.17.0.0/16`
- To channge the default IP range we can go to `/etc/dockerdaemon.json`
- modify the bridge IP and restart the docker

**Docker Network Driver**

- When a software wants to communicate with any underlying hardware, it ca not communicate directly, it needs the driver(`A apecial kind of software`) which is designed in such a way that translates the message to hardware which the hardware can understand.
- Similarly, the docker also needs a driver to communicate with the network interfaces.
- There are `3 main` types of network `drivers` available which docker uses to communicate with the network interface.
    * `Bridge` driver 
        - This is the default driver that docker uses out of the box
        - This creates a bridge between docker container and the host
        - This is one of the reasons, we promot the containers to be accessible on a specific port `-p 8080:8080` 
            [-p `host_port`:`container_port`]
    * `host` driver
        - It removes the network isolation between the docker containers and the host
        - when we run a container, we dont promote the container to use different port, it works on the same port as the host.
            - `-p 8000:8000` [X] This is not needed.
            - `ipV6` is still not supported as of June 2024.
    * `Overlay` driver
        - This network driver makes the dockers of one host to communocate with the dockers of another host 
        - So, the containes of cross docker hosts also can communicate 
        - The `OS-level` routing is not needed

    ### There are other drivers also 
    * `ipvlan` - IPvlan networks give users total control over both IPv4 and IPv6 addressing.
    * `macvlan` - Macvlan networks allows assigning a MAC address to a container, making it appear as a physical device on your network. The Docker daemon routes traffic to containers by their MAC addresses.
    * `none` - Completely isolate a container from the host and other containers.

    More about docker networking can be read from here - https://docs.docker.com/network/drivers/

    ## Docker commands to manage, maintain the docker network
    1. `Read` - List the networks of docker on your host - `docker network ls`
    <img width="362" alt="docker-nw-ls" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/c40fb330-9c3d-419a-8181-5a73c80fde4b">

    2. `Create` - Create a user defined network - `docker network create -d bridge my-net`
            - define which driver to use - here `bridge` driver is used
            - define the network name = here `my-net` is the name of the network
    3. `Read` - Get more detailed info about a particular network driver
            - `docker network inspect bridge`
            - This gives the vital info like
                - what are the containers are attached to this network
        <img width="650" alt="docker-nw-inspect" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/0d1069f5-c5f1-4a58-b938-c608f5fa4ec6">
        
    4. `Update` - Once the network is created, we can `connect` & `Disconnect` the containers into that network
        - create a host network : `docker network create -d host my-host-net`
        - connect a container into that network - `docker network connect my-host-net partho-container`
        - disconnect - `docker network disconnect my-host-net partho-container`
    5. `Delete` 
                - Deleting a single network **rm** - `docker network rm my-host-net`
                - Deleting multiple networks - `docker network rm net1 net2 net3`