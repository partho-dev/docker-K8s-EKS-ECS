## How to deploy an existing Micoservices to K8s

### Assumptions
- The microservices are already containerised and pushed into Docker registry
- Here, we would use `Mongo` image from docker hub and see how to create
    - configmap
    - secret
- Create one `mongo-express` - `UI` and make it available outside using service type - `nodeport`

- <img width="1663" alt="Mic" src="https://github.com/user-attachments/assets/2199a4b7-4164-4479-8a5b-00d058c8100a">

## 

- UI Receives the traffic from outside the cluster
- It communicates with `Mongo DB` through the service that is attached with the mongo deployment
- Mongo has passwords and DB URL, that is kept in Kubernetes resource `secret` & `configmap`

### What are the deployment & other yml files are needed
1. 1 secret.yml file to store Mongo secrets 
2. 1 config map file to store the Mongo DB URL
3. 1 Deployment file for Mongo DB & an associated service of clusterIP type
4. 1 Deployment file for UI `mongo-express` & an associated service with nodeport type.
5. minikube on the local system to test

### Lets start create the resources
1. mongoSecret.yaml
- Its a genetic type of secret, where the data would be kept with `base64` encryption
```
apiVersion: v1
kind: Secret
metadata: 
  name: mongo-secret
type: Opaque
data:
  mongo-username: cGFydGhv
  mongo-password: cGFydGhv
```

2. config file for mongo
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-config
data:
  mongo-url: mongo-service
```

3. Deployment & Service for Mongo server
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-deployment
  labels:
    app: mongo-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-server
  template:
    metadata:
      labels:
        app: mongo-server
    spec:
      containers:
      - name: mongo-server
        image: mongo:latest
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongo-secret
              key: mongo-username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo-secret
              key: mongo-password

---

apiVersion: v1
kind: Service
metadata:
  name: mongo-service
spec:
  selector:
    app: mongo-server
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
              
```

4. Deployment & Service for Web server
- expose this with service type - `nodePort`

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  labels:
    app: webapp-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-server
  template:
    metadata:
      labels:
        app: webapp-server
    spec:
      containers:
      - name: webapp-server
        image: mongo-express:latest
        ports:
        - containerPort: 8081
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME
          valueFrom:
            secretKeyRef:
              name: mongo-secret
              key: mongo-username
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo-secret
              key: mongo-password
        - name: ME_CONFIG_MONGODB_SERVER
          valueFrom:
            configMapKeyRef:
              name: mongo-config
              key: mongo-url
        

---

apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort
  selector:
    app: webapp-server
  ports:
    - protocol: TCP
      port: 8081
      targetPort: 8081
      nodePort: 30007
              
              
```

5. Now, start the minikube server on local
6. Start applying all these yaml files 
- start with the global files like secret & config files
- `kubectl apply -f mongoSecret.yaml `
- `kubectl apply -f mongoConfig.yaml `
- `kubectl apply -f mongoDeployment.yaml`
- `kubectl apply -f webDeployment.yaml `

7. Once all these files are deployed, the web server container needs to be exposed outside
- minikube_ip:8081 would not make the app accessible `minikube profile list`
- Get the list of services - `kubectl get svc `
- find the service which was exposed with nodePort type 
- Then type this `minikube service webapp-service`
- This will give the UI on browser

- <img width="653" alt="serv" src="https://github.com/user-attachments/assets/747a3190-df32-40ee-a12f-130430d8efe3">


8. Once all the tests of deployments are done
- Delete all deployments - `kubectl delete deployments --all`
- Delete secrets - `kubectl delete secrets --all`
- Delete configmap - `kubectl delete configmaps --all`
- Stop the minikube - `minikube stop`