

### How to push the images to DockerHub

- Its the time to push the image to some image repo 
- First login `docker login` - Enter your dockerhub creds
- Once the image is created, it needs to be pushed into the Docker Hub

        ```

        docker build -t express-server ./server
        docker build -t next-client ./client

        ```
    - Login to `Dockerhub`
    - Create a repository `daspratha/nextjs_express` # SOme differenet Repo based on project
    - Then from the local machine suppose if we want to push the image `daspratha/nextjs_express`
    - Then, tag your local image to repo 

            ```
            docker tag express-server daspratha/nextjs_express:express-server
            docker tag next-client daspratha/nextjs_express:next-client
            ```
    - then to push the image execute -
            ```
                docker push daspratha/nextjs_express:express-server
                docker push daspratha/nextjs_express:next-client

            ```

    ### To login to dockerhub
    - From terminal, type docker login
    - Enter Usernaame/Password of Dockerhub
    - Now, push the image `docker push dockerhub_username/your_image`


### apply all the deployment files
- start the minikube server - minikube start --memory=4098 --driver=hyperkit
- configmap - kubectl apply -f mongoConfigmap.yaml  
- api deployment - kubectl apply -f api_express_deployment.yaml  
- fe deployment - kubectl apply -f fe_next_deployment.yaml  
- Now get the nodeport IP to communocate with UI - `minikube service next-service`

### Issues faces
- This site can’t be reached192.168.64.2 refused to connect.
- Checked the FE container logs - `kubectl logs -l app=next-client`
- Found the next was starting with port `3000`, but on deployment, it is asked to point to 3001
```
 ▲ Next.js 14.2.5
  - Local:        http://localhost:3000
  ```