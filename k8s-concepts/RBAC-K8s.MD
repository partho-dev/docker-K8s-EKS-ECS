## What is RBAC
-  RBAC means - Role Based Access Control.
- In General, this is used to restrict permission on the 
    - user who is using K8s to orchestrate the containers
    - resources (ex - pods or other K8s Resources) to have access on other resources

## Why Do we need that
- We dont want a melicious user with full admin role to delete or damage any resources inside the K8s Cluster
- We dont want some pod with some melicious container application has full access on the secret or other important resources
- Providing the POD read-only access to to sensitive information stored in Secrets.
- To follow the least privilege is the best policy to avoid any kind of fatel issues later
- Any request that we pass into K8s, it passes through API server & API Server ensures the request passes these 3 A
    - API Server is the main door and it checks `3As` 
    - 1st A - `Authentication` :  The user/programm is authenticated to perform the task(It generally comes through request header)
    - 2nd A - `Authorisation` : Checks if the user is authorised to do the task based on RBAC
    - 3rd A - `Admission Control` : Its a module which modifies or reject the request. & then saves to DB (`ETCD`)
- So, if the request is not authenticated & authorised, the request would be rejected by the API server.

## Comparison with AWS IAM policy and Roles
- When we apply a policy with a user, that becomes the user policy and the user gets the authorisation to perform action on AWS based on the policy attached.
- Similarly, if we want one aws service like Ec2 to have some read access to another aws service like S3, We create a Role and then assign that role to the Ec2
- This (`AWS Role`) is the same concept as `"service account"` for K8s

## What are the components
- `User Account` 🥇 : This is used to provide leaset privilege to the `users`
    - But, the point to be remembered, its not highly recommended to create user manually for K8s, its good to offload that to 3rdparty identity provider.
    - So, to provide the access to user level, K8s depends upon the Identity provider of the platform
    - Ex - For EKS, the user level RBAC is the IAM policy that is assigned to the IAM user who is managing the cluster
- `service account` 🥇 : This is used to provide least privilege to the `K8s resources` 
- When we create a cluster, Kubernetes automatically creates a ServiceAccount object named default

- `Role` / `ClusterRole`
- `Role Binding` / `Cluster Role Binding`

    - In case of service account, we need to create role and then attach that role to a specific resource for a namespace level or cluster level
    - 1. 1st - We need to create a service Account 
    - 2. 2nd - We need to create a Role 
        - Role has 3 important `rules`
            - 1. API Group 
            - 2. Resources
            - 3. Actions - Verbs (get, post, del etc)
    - 3. 3rd - To attach the Role with the service, we need something called `Role Binding`

## How to manage the RBAC
![rbac-k8s](https://github.com/user-attachments/assets/20156dc5-3306-452b-8c60-4d3a6a9fffd6)
- 1. First create a namespace - `kubectl create namespace hello`
- 2. create a service account  - `svcaccount.yml`

    ```
        apiVersion: v1
        kind: ServiceAccount
        metadata:
        annotations:
            kubernetes.io/enforce-mountable-secrets: "true"
        name: my-serviceaccount
        namespace: devNameSpace
    ```

- 3. Now, apply the service account - `kubectl apply -f svcaccount.yml`
- 4. Now, need to create Role which would define the level of access to a developer - `role.yml` (This is similar to create `IAM policy`)

    ```
            kind: Role
            apiVersion: rbac.authorization.k8s.io/v1
            metadata:
              namespace: devNameSpace
              name: developer-role
            rules:
            - apiGroups: [""] # "" indicates the core API group
              resources: ["pods", "deployments"]
              verbs: ["get", "list", "watch"]

    ```
    - here, the user has access to only one group for all resources but within the `devNameSpace` ns

- 5. Apply the role menifest on K8s - `kubectl apply -f role.yml` [ Now this role is available in the cluster to be applied to any resources]
- 6. Now, both service account and roles are made, but they are of no use, unless we bind them together `rolebinding`
- 7. `RoleBind`  - rolebind.yml
    ```
            kind: RoleBinding
            apiVersion: rbac.authorization.k8s.io/v1
            metadata:
              name: developer-rolebinding
              namespace: devNameSpace
            subjects:
            - kind: User
              name: developer-user # Matches the IAM user or the username you set in `aws-auth`
              apiGroup: rbac.authorization.k8s.io
            roleRef:
              kind: Role
              name: developer-role
              apiGroup: rbac.authorization.k8s.io

    ```
- 8. Now, to bind the role to the service account, just apply that - `kubectl apply -f rolebind.yml`
- 9. See the role binding - `kubectl get rolebindings -A`

***

## Analogy with AWS IAM Policy with Role(For namespace level) clusterRole (Cluster Level)

### AWS IAM Policies and Their K8s Equivalent

- AWS IAM Policy:
  - Defines a set of permissions (e.g., `s3:ListBucket, ec2:StartInstances`).
  - Can be attached to multiple entities (`users, groups, roles`).

- Kubernetes Role/ClusterRole:
  - Defines a set of permissions (e.g., `pods: get`, `deployments: list`).
  - `Role`: Applies within a specific `namespace`.
  - `ClusterRole`: Applies `cluster-wide` (across all namespaces).
  - Can be assigned to multiple users or service accounts.

- Applying Permissions in AWS and Kubernetes
    - AWS IAM Role or Group: The policy that we creat can be attached to any IAM resources like users, groups or roles and that defines the access.

- Kubernetes RoleBinding or ClusterRoleBinding:
  - Attach a Role or ClusterRole to a user, group, or service account via a RoleBinding (for namespace-scoped roles) or ClusterRoleBinding (for cluster-scoped roles).

- Example Mapping
  - AWS IAM Policy → K8s Role/ClusterRole:
        Both define what actions are allowed on specific resources.
  - AWS IAM Role → K8s RoleBinding/ClusterRoleBinding:
        Both bind the permissions (IAM Policy / Role) to a user or entity (IAM Role/Group or Kubernetes User/ServiceAccount).

- Example Use Case:
- `AWS:` - IAM Policy: A policy grants access to EC2 and S3 (Ec2toS3)
```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["ec2:*", "s3:*"],
                "Resource": "*"
            }
        ]
    }
```
- Once this policy(Ec2toS3) is created, it can be attached to a single or multiple IAM resources

- `Kubernetes`:
  - ClusterRole: A ClusterRole grants access to pods and deployments `cluster-wide`.

```
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: dev-cluster-role
  rules:
  - apiGroups: [""]
    resources: ["pods", "deployments"]
    verbs: ["get", "list", "watch"]
```

- This ClusterRole can be applied to multiple users or service accounts via a ClusterRoleBinding:
- Cluster Role Binding

```
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: dev-cluster-role-binding
    subjects:
    - kind: User
      name: developer1 # Name of the user
      apiGroup: rbac.authorization.k8s.io
    - kind: User
      name: developer2
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: ClusterRole
      name: dev-cluster-role
      apiGroup: rbac.authorization.k8s.io
```
In both AWS and Kubernetes, policies (AWS) and roles (Kubernetes) define what actions are permitted, while roles (AWS) and role bindings (Kubernetes) determine which users get those permissions.


---

## What are the ways to manage users in K8s
- 1. Using 3rd party Identiyty providers and the common method are - `OAuth/OIDC Providers(eg; google, github etc)`

### 2. Create user manually using certificates (Little complex :adult:)
- To see the list of existing user on the cluster 
    - `kubectl config get-users`
    - See in details - `kubectl config view `

### 3. List the current user permission 
- use `kubectl auth can-i <verb> <resource>`
- `kubectl auth can-i list pods`

### 4. To List all permissions  
`kubectl-access-matrix`
- install a plugin `access-matrix`
- First Install the plugin - `kubectl krew install access-matrix`
- after install execute this - `kubectl access-matrix`

### 5. `Changing` the users : 
- To change the user, `context` switch is needed in the kubeconfig file. 
- Each context is tied to a specific user, cluster, and namespace.

**List all context**
- `kubectl config get-contexts`

**Set the Current Context**
- Switch to a different context to change the user
- `kubectl config use-context <context-name>`

***
    

## How to create users in Kubermnetes
* ✅ 3 different files would be created in sequence
    - 1st one would be `.key` 🔥
    - 2nd one would be `.csr` 🔥
    - 3rd one would be `.crt` 🔥
* ✅ once the `.crt` is created, its the time to create role & rolebinding
* ✅ Lets see things in action below 

- Get the complete info from the K8s Document - https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#normal-user
- Generally, the user and user access is good to have through some 3rd party identity provider
- But, if there is a need to create a user in K8s, we have to do that in this following way

- **Remember**
    - There is no username & password for any user to connect to K8s, API server authnticate the user through the token key
- So, we have to create Key for the user

1. Generate certificate (`Private Key`) for the user `sam` using 2048 bytes using `openssl` on your local laptop
- This gives output as `sam.key`
```
openssl genrsa -out sam.key 2048
```

2. See the key - `vi sam.key `

3. Create the `CSR- Certificate Signing Request` request for the certificate  on your local laptop
- Create a CSR for the user with the Common Name (CN) set to `sam` and the Organization (O) is set to `examplegroup`.
- This gives output as `sam.csr`
```
openssl req -new -key sam.key -out sam.csr -subj "/CN=sam/O=examplegroup"

```
4. check it on your local laptop - `ls sam.*`

5. Now encode the above CSR in base 64 format - `cat sam.csr | base64 | tr -d "\n"`

- <img width="520" alt="64" src="https://github.com/user-attachments/assets/b671524f-6498-494b-89f7-4e575843cfe5">

6. Create a CertificateSigningRequest (CSR) Object in Kubernetes
- copy a CertificateSigningReques template from K8s docs. https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest
```
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: sam   
spec:
  request: <Replace this with the output from the previous step>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

```
- <img width="922" alt="CA" src="https://github.com/user-attachments/assets/19fc85a5-7fd9-4393-9cd1-7738ed19db3b">

- 👉 Check if the CSR status - `kubectl get csr`
- It should be `Pending`

**Note** 👉 :  To Delete the CSR - `kubectl delete csr sam`

7. This will give output as `certificatesigningrequest.certificates.k8s.io/sam created`

8. Now, to move the CSR from Pending to Approve, execute the below command

```
kubectl certificate approve sam
```
- 👉 <img width="752" alt="CSR" src="https://github.com/user-attachments/assets/16a69b5d-ed63-4218-a5e1-ec8c71362db1">

9. Once its `approved`, its the time to retrieve that generated certificate (`.crt`)
- This gives output as `sam.crt`

```
kubectl get csr/sam -o jsonpath="{.status.certificate}" | base64 -d > sam.crt
```

10. Create a configuration specific to the user
```
kubectl get csr/sam -o jsonpath="{.status.certificate}" | base64 -d > sam.crt
```

```
cp ~/.kube/config sam-kube-config
```

### Add the user to kubeconfig 👨‍💻

11. Set the credentials for the user in the new kubeconfig file.

```
kubectl --kubeconfig=sam-kube-config config set-credentials sam --client-key=sam.key --client-certificate=sam.crt --embed-certs=true
```

12. Set the context for the user in the new kubeconfig file.
```
kubectl --kubeconfig=sam-kube-config config set-context sam --cluster=<Cluster-Name> --namespace=default --user=sam
```
13. Use the New kubeconfig File 
- To access the cluster as a `sam` user, we have to change the context to `sam`
```
export KUBECONFIG=sam-kube-config
kubectl config use-context sam

```


## Lets get things in action
* Create a user and give the user permission to only List the pods, but not Create or Delete the pods

- From the above the user is created, now we have to create
1. Role with rules to have only read only access to pods
2. RoleBinding

1. Create role menifest file
- `role.yml`
```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: sam-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
- Then apply that to K8s Cluster 
- `kubectl apply -f role.yml`

2. Create role binding `rolebinding.yml`
```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sam-rolebinding
  namespace: default
subjects:
- kind: User
  name: sam
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: sam-role
  apiGroup: rbac.authorization.k8s.io
  
```
- Then apply that to K8s Cluster 
- `kubectl apply -f rolebinding.yml`

---

## How to create IAM user and assign RBAC to the user

- ![K8S-RBAC-Explained](https://github.com/user-attachments/assets/de5c0818-a01c-4e05-9d9a-7aac3093be08)


- User Persona - 1 : Admin with full access : This user has full access to create the cluster, create, read, update, delete the resources on the cluster
- User persona - 2 : `Developer` : This user access is being controlled by the role that is assigned to him

### What the admin does 
- Admin ensures he creates IAM user (in the case the Developer user was created by the admin)

- He can create the IAM user 

    - either from AWS console with no policy attached or with very less prevelige
    - or he can use `aws cli` and execute command from his laptop to create the developer user
        - `aws iam create-user --user-name developer-user`

- Once the user is created, he would create the access/secret key for that `developer-user`
    - `aws iam create-access-key --user-name developer-user`
    - Note down the keys and share that with the developer user through email or some other means

- Admin creates the EKS cluster from his laptop 
    - `eksctl create cluster --name myEKS --node-type t2.large --nodes 1 --nodes-min 1 --nodes-max 2 --region ap-south-1 --zones=ap-south-1a,ap-south-1a`
- Admin can delete the cluster
    - `eksctl delete cluster --name myEKS --region ap-south-1`

- Admin creates the necessary deployments, namespace needed
    - create a namespace which would be used by developer - `kubectl create namespace devNameSpace`

- Admin can execute any deployments to deploy a container on EKS - `kubectl apply -f webapp.yaml` [webapp.yaml is a deployment which has all the info on how many replica is needed, the image etc]
    - This can be done even by the `developer-user` if he has the access to create deployment [ We will see that in a moment]

- Admin can list all the deployments in the namespace that was created
    - `kubectl get all -n devNameSpace` [`kubectl get deployments -n devNameSpace`]

- Once the user is created, that user needs to be mapped with the EKS cluster, so that any application if needed to have access to user, it can be used
    - `kubectl apply -f map_user.yaml`
    - In our this scenerio, this resource is not needed
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: user_authentication
  namespace: devNameSpace
data:
  mapUsers:
    - userarn: <developer-user_arn>
      username: developer-user
```

### But, how the Admin is able to do all these?
- Because the Admin has these 3 tools installed in his laptop
    - aws cli
    - eksctl
    - kubectl

### How the Developer access the cluster and perform the tasks
- Once the `developer-user` receives the accesskey & secret access key from admin
- `developer-user` will configure his local laptop to communicate with AWS EKS
- `aws configure ` & fill all the info 
- install the `kubectl` tool 
- Update the `kubeconfig` to recognise the `EKS` custer, using `eksctl utils`

```
eksctl utils write-kubeconfig --cluster <cluster-name>

```

- now try to execute the command - `kubectl get deployments -n devNameSpace` 
    - But, he would get an error and can not access the deployments, because the `API Server` on control pane is rejecting his request.
    - So, he requests the admin to provide him access to see the deployments

- Admin does the below things to get the developer access
- Admin creates a `Role` & then `Rolebind` resources as below

```
# Role - role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: devNameSpace
  name: test_role_name #unique name of the role
rules:
  - apiGroups: [""]
    resources: ["deployments"] 
    verbs: ["list", "get"]

```

```
# RoleBinding - rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: devNameSpace
  name: test_role_name #It can be same name of the role
subjects:
  - kind: User
    name: developer-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: test_role_name
```

- Then Admin applies that to the cluster 
- `kubectl apply -f role.yaml`
- `kubectl apply -f rolebinding.yaml`

- Now, when the `developer` is trying to execute the command from his laptop
- `kubectl get deployments -n devNameSpace` #able to get the list of deployments

- But, while he tries to execute `kubectl delete deployments deployment_name`
    - This operation does not perform, because the ROle attached to this user does not have this authorisation
    - so, the API Server rejects this request
    - To enable that delete, the admin has to update the role file with verb verbs: `["list", "get", "delete"] `



## Important items to note: 
- When we create a cluster, Kubernetes automatically creates a ServiceAccount object named default

---

## How to manage many users to have access the Kubernetes cluster
- This includees somestandard procedures for both the admins and the developers

