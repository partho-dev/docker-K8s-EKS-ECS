## What is docker
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
        - [-p `host_port`:`container_port`]
        - we can create our own custom bridge network to isolate certain containers
        - `docker network create -d app-net`
    * `host` driver
        - It removes the network isolation between the docker containers and the host
        - This can be a security burden for some secure applications
        - when we run a container, we dont promote the container to use different port, it works on the same port as the host.
            - `-p 8000:8000` [X] This is not needed.
            - `ipV6` is still not supported as of June 2024.
        - We can not create `host` network
        - but we can run some container on `host` network like this
            - `docker run -d --network host --name partho-container partho-image`
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
        - disconnect - `docker network disconnect my-bridge-net partho-container`
    5. `Delete` 
        - Deleting a single network **rm** - `docker network rm my-bridge-net`
        - Deleting multiple networks - `docker network rm net1 net2 net3`


    ## Lets get more into the docker Networking:
    1. list the networking - `docker network ls`
    2. inspect all the 3 networks and take a look at the `IPAM config`
        * `docker network inspect bridge` 
            IPAM.config should have value of network as `docker0` 
                "Subnet": "172.17.0.0/16",
                "Gateway": "172.17.0.1"
        * `docker network inspect host`
                nothing, because it maps the container nw with the host machine nw
        * `docker network inspect none`
                There is no networking, insecure

    ###  Prove that the containers in default bridge network can not communocate with container from a custom bridge network
        * Create a custom bridge network - `docker network create -d bridge isolate-net`
        * docker network ls - This will list the newly created network under bridge driver
        * Now, create two containners
            * one with default bridge network 
                - `docker run -d --name default-nginx-container nginx`
                - ispect the default bridge network and find the container IP 
                    - IP : 172.17.0.2/16
                    - subnet : 172.17.0.0/16
                    - gateway : 172.17.0.1
                - Go inside this container and install `ping` - `docker exec -it default-nginx-container /bin/bash`
                - `apt-get install -y iputils-ping`
            * create another container on the custom bridge network
                - `run -d --network isolate-net --name isolate-nw-container nginx`
                - ispect the custom isolate bridge network and find the container IP 
                    - IP : 172.18.0.2/16
                    - subnet : 172.18.0.0/16
                    - Gateway : 172.18.0.1
            * If we carefully see, both the containers are of totally two dofferent networks (one is at 17 network and another on 18 network) and so they can not communicate. 
            * we can further ping `172.18.0.2` from the default network containers
                - <img width="520" alt="docker-new" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/1b65d306-a3ed-41f1-96e6-db88ad7866ad">
                - This shows that two containes of two different bridge network are totally isolated
            
    ###  How to remove a container from one network
        - `docker network disconnect net-name container-name`
    
    ###  How to know if any network which does not have any container
        - This will list the network-Id who has one or more container attached `docker network ls -q`
    
    ## Lets see some Docker in easy fun way
    - You have to create an image - `docker build -t your-image .`
    - Curious to see the list of all images - `docker images`
    - curious to see whats inside a single image - `docker image inspect image-id`
    - Now, you want to create a container out of that image - `docker run -d --name your_container -p systemPort:containerPort your_image`
    - Want to see the list of container - `docker ps` or `docker ps -a` [To see **a**ll container]
    - curious to go inside the container and see your code - `docker exec -t image_id /bin/sh`
    - trying to create a file, but its giving "permission denied" - Chek the user `whoami` or `id` - Its a non root
    - exit out of the container by typing `exit` and go inside again as a root user - `docker exec -it --user root image_id /bin/sh`
    - you want to stop or pause the container at night - `docker stop container_id` 
    - You want to know about networking now, - `docker network ls`
    - to know more about each network to know how many containers inside the network or other info - `docker network inspect network_id`
    - You want to create an isolated bridge network to host a standalone container - `docker network create -d bridge new_net`
    - now you want to connect an existing container from another network to be attached with your new network - `docker network connect new_net container-id`
    - to verify if the container got attached with the new_net, inspect the container - `docker ispect container_id` Look for "Networks" block
    - You can easily disconnect the container also from this network and the container gets attached to the default bridge nw - `docker network disconnect new_net container_id`
    - You want to know what is happening to a certain container - `docker logs container-id -f`
    - Now, you got more curious and want to know which container is taking more resource from you laptop    
    - `docker stats` or `docker top container_id`
    - Now, you found that your db table info are gone from Mysql container, so you want to set a volume to retain the data
        
    ## To set the volume to a container, there are two methods 

    **Docker Volume**
        * First you create a volume - `docker create volume my_volume`
        * see its status = `docker volume ls`
        * To know more about that volume, ispect the volume - `docker inspect volume your_volume_name`
        * then you can assign that volume to a new container - `docker run -d -v partho-volume --name new-cont-0 -p 3000:3000  daspratha/express:v1`

    **Bind Mount**
        * In this, you dont need to create any volume upfront, this method can mount host any volume with container
        `docker run -d -v $(pwd):/app --name new-cont-1 -p 3001:3000 daspratha/express:v1`
        
    ### Now you are confused which one to use?
    - In easy way to remeber, for development, its good to go with `Bind Mount` method
    - for prod go with `Docker volume`

    ## You need to use some **environment varibale** to be passed into your container application, 
    - which can also be done in `two ways`
    - Pass one value of environment, use the flag `-e key="value"` 
        - `docker run -d -v $(pwd):/app -e PORT="3030" --name new-cont-2 -p 3001:3030  daspratha/express:v1`
    - Pass multiple environment - add multiple `e` 
        - `docker run -d -v $(pwd):/app -e PORT="3030" -e ENV="dev" --name new-cont-2 -p 3001:3030  daspratha/express:v1`

    - Pass the entire .env file as a flag `--env-file ./.env`
        - `docker run -d -v $(pwd):/app --env--file ./.env --name new-cont-3 -p 3001:3030  daspratha/express:v1`

    ## Now, once all the development is completed, you would like to delete or remove all un-used resources 
    - `docker system prune` 
    - `docker system prune -a` This removes the cache also.

    ## How to retain the state of a container
    - The container has some good changes, and you want to save the same state of container 
    - `docker commit container_id new_image_name`

    ## How to push the image to remote repo
    - Its the time to push the image to some image repo 
        - First login `docker login` - Enter your dockerhub creds
        - Now, push the image `docker push dockerhub_username/your_image`
