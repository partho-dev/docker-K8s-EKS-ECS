=========Deploy Angular application to kubernetes========
Process / Steps:
As angular works using dist build
Create a multistage Dockerfile 
Stage-1: node
Stage-2: nginx
Create a docker image from the Angular code
Run the container to check on the localhost.
push the image to dockerhub for the k8s to fetch to create the pod
docker -t angular-app:1.0 daspratha/angular-app:1.0
docker push daspratha/angular-app:1.0
Enter Dockerhub U/P
To deploy on k8S, need to create deployment file
Deployment folder > angular_deployment.yaml
update the image name “daspratha/angular-app:1.0” into the deployment file under container image section
kubectl create -f deployment/angular_deployment.yaml
Check the status of the pod
kubectl get pods


```
#stage 1
FROM node:latest as build
RUN mkdir -p /app
WORKDIR /app
COPY package.json /app
RUN npm install
RUN npm install -g @angular/cli
COPY . /app
RUN ng build --prod


#stage 2
FROM nginx:latest
COPY --from=build /app/dist/angularProject /usr/share/nginx/html
EXPOSE 80

```

keep Dockerfile on the root folder of the Angular 
from terminal of same relative path as the above code, build the docker image.
docker build -t daspratha/angular-hw-image:latest .   [ # There is a . (dot) at the end, which means, create it on the same root folder]
Run the docker container using the above image
docker run -d --name angular-hw-container -p 80:80 partho/angular-hw-image
For consistent data, map the volume with the container  [ But the changed didnot get reflect to the container ]
docker run -d --name angular-HW-container -v /Users/partho/Desktop/Angular_HelloWorld_K8S:/app -p 80:80 partho/angular-hello-world

