- Setting up wordpress on local.

- docker compose file - `compose.yaml`

```
volumes:
  dbdata:
  wordpress:

networks:
  internal:
    driver: bridge

services:
  nginx:
    container_name: ${CONTAINER_NAME}-nginx
    image: nginx:1.15.12-alpine
    restart: unless-stopped
    env_file: .env
    ports:
      - "8080:80"
    volumes:
      - ./nginx:/etc/nginx/conf.d:rw
      - wordpress:/var/www/html
    networks:
      - internal

  mysql:
    container_name: ${CONTAINER_NAME}-db
    image: mysql:8.0
    restart: unless-stopped
    env_file: .env
    environment:
      MYSQL_DATABASE: "${DATABASE_NAME}"
      MYSQL_PASSWORD: "${DATABASE_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${DATABASE_ROOT_PASSWORD}"
      MYSQL_USER: "${DATABASE_USER}"
    ports:
      - "3307:3306"
    volumes:
      - dbdata:/var/lib/mysql
    networks:
      - internal

  phpmyadmin:
    container_name: ${CONTAINER_NAME}-phpmyadmin
    image: phpmyadmin/phpmyadmin
    env_file: .env
    environment: 
      PMA_HOST : mysql
      PMA_PORT : 3306
      MYSQL_ROOT_PASSWORD : "${DATABASE_ROOT_PASSWORD}"
    ports:
      - "8081:80"
    networks:
      - internal

  wordpress:
    depends_on: 
      - mysql
    container_name: ${CONTAINER_NAME}-wordpress
    image: wordpress:6.5.2-fpm-alpine
    restart: unless-stopped
    env_file: .env
    environment:
      WORDPRESS_DB_HOST: mysql:3306
      WORDPRESS_DB_NAME: "${DATABASE_NAME}"
      WORDPRESS_DB_USER: "${DATABASE_USER}"
      WORDPRESS_DB_PASSWORD: "${DATABASE_PASSWORD}"
    volumes:
      - wordpress:/var/www/html
      - ./src:/var/www/html
    networks:
      - internal
```

- Points to note:
    - The volume needs to be named volume for the mysql
    - create a bind mount for wordpress service to get all the codes from container into the development work space
    - This code would be used to create a docker file for production purposes.

- The services mentioned on the compose would rely on some environment variables, so we would need them to be declared outside 
- .env file
```
CONTAINER_NAME = blog-site

# For local mysql
DATABASE_NAME=wordpress
DATABASE_USER=partho
DATABASE_PASSWORD=secret
DATABASE_ROOT_PASSWORD=secretpass


#For local wordpress
WORDPRESS_DB_HOST=mysql:3306
WORDPRESS_DB_NAME="${DATABASE_NAME}"
WORDPRESS_DB_USER="${DATABASE_USER}"
WORDPRESS_DB_PASSWORD="${DATABASE_PASSWORD}"
```

- Now its time to fire the compose and get the local wordpress site ready
- `docker compose up -d --build`
- localhost:8080 - The site would not work, instead it will show the default nginx page, because we have not overwritten the config file.
- create a folder(nginx/) on the same path and create a file(default.conf) (nginx/default.conf)
- update this contennt

```
server{
    listen 80;
    root /var/www/html;

    location / {
        index index.php index.html;
    }

    location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass wordpress:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
  }
}
```


---

- All fine till now, but how to deploy this to production on Kubernetes 

- Things to remember
- Need to create an image from the wordpress codes that we binded to our locla file system (.src)

- dockerfile
```
FROM wordpress:6.5.2-fpm-alpine

# Replace PHP-FPM config to listen on TCP port 9000
RUN sed -i 's/listen = .*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.d/zz-docker.conf

COPY ./docker/src /var/www/html/
# RUN rm -rf /var/www/html/wp-admin && \
#     chown -R www-data:www-data /var/www/html

RUN chown -R www-data:www-data /var/www/html

# This ensures the permission to load css & image on target eks 
RUN chmod -R 755 /var/www/html/wp-content/themes
    # chmod -R 755 /var/www/html/wp-content/uploads

EXPOSE 9000
```

- build this as a docker image and then push that to the repo
- `docker build -t nexus.domain.com/docker-hosted/wordpress:v1 .` # For private repo
- `docker build -t daspratha/wordpress:v1 .` #For public repo like dockerhub

- Push the image 
- `docker push nexus.domain.com/docker-hosted/wordpress:v1`
- `docker push daspratha/wordpress:v1`

---
- Creation of kubernetes menifests
- planning : we need to route the traffic to wordpress pod through nginx pod, because the wordpress is a php application and it needs some php fpm pass


- so need two deployments (nginx-deployment & wordpress-deployment).yaml files
- So, the traffic would flow like this
- ingress gives the traffic to nginx service on port 80
- nginx service gives the traffic to wordpress service over port 9000, so we would need to update the nginx default config file with our custom config to proxy pass the traffic to wordpress
- Then wordpress would connect with RDS mysql DB on private subnet, so we would need to do sqldump from local to exported to rds :(

- There are a lot of files.
Lets create them one by one

- 1. nginx-deployment.yaml
- This will include the custom nginx config that we would need to pass the traffic to next service, wordpress
- the nginx service

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configmap
  namespace: ns-wordpress
data:
  default.conf: |
    server {
      listen 80;
      server_name blog.domain.com;

      root /var/www/html;

      location / {
        index index.php index.html;
        try_files $uri $uri/ /index.php$is_args$args; 
      }

      location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass wordpress:9000;
      }
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: ns-wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: nginx-configmap
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: ns-wordpress
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: nginx

```

- 2. wordpress-deployment.yaml
- Make sure, the efs csi driver component is already setup on the eks/kubernetes
- and the nexus allows the eks to pull imahe, so set the nexus creds on eks through service secret on the same ns

```
---
# Create PVC
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
  namespace: ns-wordpress
spec:
  accessModes:
    - ReadWriteMany  
  resources:
    requests:
      storage: 10Gi
  storageClassName: efs 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: ns-wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      imagePullSecrets:
        - name: nexuscreds
      containers:
        - name: wordpress
          image: nexus.domain.com/docker-hosted/wordpress:v1          # image: wordpress:6.5.2-fpm-alpine
          env:
            - name: WORDPRESS_DB_HOST
              value: "blog-aurora-cluster.cluster-c0cpt.ap-south-2.rds.amazonaws.com"
            - name: WORDPRESS_DB_NAME
              value: "blogdb"
            - name: WORDPRESS_DB_USER
              valueFrom:
                secretKeyRef:
                  name: wordpress-secrets
                  key: DATABASE_USER
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: wordpress-secrets
                  key: DATABASE_PASSWORD
          volumeMounts:
            - name: wordpress-data
              mountPath: /var/www/html
      volumes:
        - name: wordpress-data
          persistentVolumeClaim:
            claimName: wordpress-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: ns-wordpress
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
  selector:
    app: wordpress
```

- 3. secret.yaml for wordpress to authenticate with RDS
```
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-secrets
  namespace: ens-wordpress
type: Opaque
data:
  DATABASE_USER: XJlVzZXI=
  DATABASE_PASSWORD: XJhc3M=
```

4. Finally the ingress that would bring the traffic from internet to this application
- make sure the nginx ingress controlle is already setup with proper cert manager to terminate the ssl
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
  namespace: ns-wordpress
  annotations:
    cert-manager.io/cluster-issuer: http-01-production
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-body-size: "5000m"
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
spec:
  ingressClassName: external-nginx
  rules:
    - host: blog.domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
  tls:
    - hosts:
        - blog.domain.com
      secretName: blog-domain-com
```

---
- Now, start applying these menifests to the eks
- go to domain.com 
- It will make you to install wordpress again, but this is not what we want, we want all the blogs that we wrote on local wordpress, should be visible here
- Its because the DB of local needs to be dumped on the RDS

---
- Challenges
- 1. mysql db is inside a container,so we need to dump from that
- 2. after that we cant directly export to RDS from our local system, because RDS is in private subnet and it only has access from EKS 
- So, we need to use existing two pods like nginx or wordpress, but, these two pods dont have mysql client installed
- So, we need a dedicated mysql client pod on the same ns which would only be used to do this mysql export work

- So, we need a pod deployment file first
```
apiVersion: v1
kind: Pod
metadata:
  name: mysql-client
  namespace: ns-wordpress
spec:
  containers:
    - name: mysql-client
      image: mysql:8.0     # or another lightweight image with mysql client tools
      command: ["sleep", "3600"] # Keep the pod alive for interaction
      env:
        - name: MYSQL_HOST
          value: "blog-aurora-cluster.cluster-c0cpt.ap-south-1.rds.amazonaws.com"
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: wordpress-secrets
              key: DATABASE_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpress-secrets
              key: DATABASE_PASSWORD
```

- now we are all set to start the db dump work

- from local docker mysql container, get the db dump
- `docker exec blog-site-db /usr/bin/mysqldump --no-tablespaces -u partho --password=**** wordpress > wordpress.sql`
- Now the sql file is on the local laptop,
- sometimes, the db would be corrupted or some issues, so we have to clean that
- `tr -cd '\11\12\15\40-\176' < /local/path/wordpress.sql > /local/path/cleaned_wordpress.sql`

- then copy the cleaned db to the temporary mysql clinet pod
- `kubectl cp .\cleaned_wordpress.sql mysql-pod:/tmp/cleaned_wordpress.sql -n ns-wordpress`
- then exec to that pod and apply the db with rds
- `mysql --binary-mode=1 -h blog-aurora-cluster.cluster-it.ap-south-1.rds.amazonaws.com -u DBUser -p prodblogdb < /tmp/clean_wordpress_backup.sql`

- Now, all set, so hit - `blog.domain.com`
- But it will not work, but, it wll add :8080 in the domain like this - `blog.domain.com:8080`

- This is because the db table named `wp_options` has the sitename and url as : `localhist:8080`
- so, now we have to update this table on production RDS

- exec to temporary mysal pod - `kubectl exec -it mysql-client -n ns-wordpress -- /bin/bash`
- then connect to rds - `mysql -h blog-aurora-cluster.cluster-ct.ap-south-1.rds.amazonaws.com -u DBUser -p` 
- and then execute this
```
USE prodblogdb;

UPDATE wp_options SET option_value = 'https://blog.domain.com' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://blog.domain.com' WHERE option_name = 'home';

```

- then reload the wordpress & nginx deployment - 
```
kubectl rollout restart deployment/nginx -n ns-wordpress
kubectl rollout restart deployment/wordpress -n ns-wordpress
```


- We can automate this now using Jenkins cicd