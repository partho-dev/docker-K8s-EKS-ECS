# docker-K8s-EKS-ECS
This repo will include all about the containerization

# What is docker container and what is K8s Pod
- docker container : This runs a single instance of an application, it can be managed and maintained by the docker. 
- K8s Pods : It is an abstruction in K8s cluter which can have one or more container within.

# What are the ways, we can troubleshoot issues related to docker containers.
* See the logs - `docker logs container_name`
* See the logs in real time - `docker logs -f container_name`
* inspect the container - `docker inspect container-id`
* Get the stats of all container - `docker stats`
* Docker system information - `docker info`
* To see the running process in a container - `docker top contaoner-id`

# How to delete unused docker resources like 
- image 
    list all images - `docker images`
    delete all `un-used` images - `docker image prune `
- container
    list all the contaioners - `docker ps`
    delete all `stopped - unused` containers - `docker container prune`
- volume : Dete unused volumes
    docker volume prune 
- network : If there is any custom network, but no containers are attached, that network can be deleted
    docker network prune
- Remove all at once - `docker system prune -a`

# How to know which network is having any containers attached.
1. `docker network ls -q`
2. shell script to inspect each network and loop through them

```
#!/bin/bash

# List all networks
for network in $(docker network ls -q); do
  # Check if the network has no containers attached
  if [ -z "$(docker network inspect -f '{{.Containers}}' $network | grep -v '{}')" ]; then
    echo "Pruning network $network which has no containers attached."
    docker network rm $network
  fi
done

```

## How to restrict a container to have 1 CPU & 1GB Ram
`docker run -d --cpu 1 --memory 1g --name partho-container nginx`

## In the docker file, what is the difference between run & cmd 
   - `run` : This is used during the container creation and starting the container(starting the machine)
   - `cmd` : This runs the commands inside the container once the container is ready (executing ifconfig command inside the machine to know its IP address)

## Basic Dockerfile
-  ```
        # Use the official Nginx base image
        FROM nginx:latest

        # Set the working directory in the container
        WORKDIR /usr/share/nginx/html

        # Copy the content of the current directory to the container
        COPY . .

        # Expose port 80 to the host
        EXPOSE 80

        # The default command to run when the container starts
        CMD ["nginx", "-g", "daemon off;"]

    ```
    * Dockerfile has to be kept on the same working directory where the source code is
    * Thats why we use `.` while building the image
        - `.` represents to find the Dockerfile on the current directory
        - `docker build -t partho-image .`
    
## Multistage Dockerfile
- This is mostky used if there are multiple stages of image creation.
- This reduces the image size and so less files and dependancies, so its better for security
```
        # Stage 1: Build
        FROM node:16-alpine AS build

        # Set the working directory
        WORKDIR /app

        # Copy the package.json and package-lock.json
        COPY package*.json ./

        # Install dependencies
        RUN npm install

        # Copy the rest of the application code
        COPY . .

        # Build the React application
        RUN npm run build

        # Stage 2: Run
        FROM nginx:alpine

        # Copy the built React application from the build stage
        COPY --from=build /app/build /usr/share/nginx/html

        # Expose port 80
        EXPOSE 80

        # Start nginx
        CMD ["nginx", "-g", "daemon off;"]

```     
* Then create an image using that multistage Dockerfile
    - `docker build -t multi-stage-image .` 
* Using that image, build a container
    - `docker run -d -p 80:80 --name multi-stage-container multi-stage-image`

## Update the Docker container without Dataloss to a new image
1. Volume must be mounted on the container, so that the data is persistant on Docker volume
    - `docker run -d --name partho-container -v my-laptop-path:/path/to/container/data partho-image` - > This command is just to show how to mounnd a system volume to container
    - inspect the container and check the volume section to know the directory which is mounted to the container
2. Take a backup of the data 
    - `docker run --rm -v my-volume:/volume -v $(pwd):/backup busybox tar cvf /backup/backup.tar /volume`
    or
    - `docker run --rm --volumes-from <container> -v $(pwd):/backup busybox tar cvfz /backup/backup.tar <container-path>`
        
3. stop the container `docker stop container-id`
4. Remove old containner to avoid any conflict - `docker rm current-container`
5. pull the latest image - `docker pull new-updated-image:latest`
6. Start the new containner with new image and old data - `docker run -d --name new-container -v my-volume:/path/to/data new-updated-image:latest`

# How to move one container from one Host-1 to Host-2
* Perform all the above steps like stop, backup the data etc
    It can be done manually as well, 
        - ssh to Host1 and inspect the container and find the path of the volume (`cd /user/data`) and then stop the container
        - Now, zip the backup folder 
            - `tar cvf backup.tar .`
        - move the tar file to `2nd Host`, where the comtainer would need to come
            - `scp backup.tar user@Host2:/user/data`
            - `cd /user/data`
            -  extract the backup `tar xvf backup.tar`
            - Create the new container on Host2 with the previous data
                - `docker run -d --name container2 -v /user/data:/path/to/container/data partho-image:tag`
    To do that automatically, 
        - we can nwrite a script and do that

# How to Restoring a backup container - `docker run --rm --volumes-from <container> -v $(pwd):/backup busybox sh -c "cd <container-path> && tar xvf /backup/backup.tar --strip 1"`

# How to ensure the containers are secure to host some secure application
 * Get the image which are trusted 
 * Maintainn the underlying host with latest patches annd regular updates
 * Regularly scan the image for any vulnerability - 
    - Tools like `trivy`
    - install on your local system - `brew install trivy`  # For mac
    - Test `trivy image nginx:latest`
    - Review the list of identified vulnerabilities, including severity levels (e.g., CRITICAL, HIGH, MEDIUM, LOW).
    - Update the Dockerfile to use a more recent base image if vulnerabilities are found in the base image.
 * Enable observability to check the logs and alerts
    - enable prometheus to observe and use graphana to see it visualy or some stack like ELK [`elasticSearch Logstash Kibana`] 
    - Or we can use docker own command like docker stats, docker top etc

  # What are the best practices of Docker as a contaoiner.
  1. Use lightweight image to avoid getting any attack and optimse the the build and deployment
  2. Patch the Host and use the latest image for container
  3. Use some orchestration tool like K8s to manage containers at scale and enable the features like LB and Auto Healing etc
  4. Enable resource limit using --cpu --memory etc
  5. Monitor the container health, resource usage(`docker stats`)
  6. ENable custom bridge network and keep the containers isolated to prevent any security compromise
  7. Regularly back up the data - use some shell scripts to do that daily 
  8. Check the vulnerability test usinh tools like `trivy`