> # Authentication and Authorization in EKS

<img width="976" alt="EKS-Authentication-method" src="https://github.com/user-attachments/assets/9ce68ab5-7b17-407e-a320-5d2063ddf1ec">

### *The above flowchart gives an idea on how the authentication mechanism chages based on the source of authetication*


Kubernetes (K8s) provides some mechanism to control access to its resources, ensuring that only authenticated and authorized users or applications can interact with the API server.

- Any communication inside the EKS has to pass through the API Server
- The API Server looks for 3 things
    - Authentication (This is the process to see if the user exists)
    - Authorisation ( This pricess ensures the above existed use has permission to do the task he is requesting for)
    - Admission COntrol

- In the context of Amazon Elastic Kubernetes Service (EKS), these mechanisms are tightly integrated with AWS Identity and Access Management (IAM).

- But, we have to ensure that there are two kinds of users/applications who need to pass through the API server to perform some action inside the EKS cluster

1. There are some applicatons who is already deployed inside the EKS and its living in a POD.
- That application may need to perform some action inside the EKS, but as per the K8s policy, all the communication has to go through API server
- For that the application must pass the `Authentication` & `Authorisation` process
- For this kind of EKS internal applications like `Jenkins` who needs to create more workder temporary pods inside the same cluster
- `Jenkins` application needs to have some mechanism to authenticate itself as a valid user  and then to perform some pod, 
- it needs to have enough permission to `create`, `delete` `pod` etc through `rolebindig`

Lets see - How that works for any application who is already inside the EKS cluster.
## Internal Application Authentication
- First we need to ensure that the application has some kind of valid `credentials` for Authentication
    - 1. If the application is deployed in a namespace, it would automatically get one Service Account.
    - 2. But, we will create one custom Service Account (Equivalent to a User) for that NS where the application POD lives
        - `kubectl create serviceaccount <service-account-name> -n <namespace>`
    - 3. Now, we need to get some username/password for that user, but for SA that can be done using a `token`
        - Create a token ( for K8s version 1.24 creation of token becomes very easy)
        - `kubectl create token <service-account-name> -n <namespace>`
        - Here, the token(user/pass) is created for the SA and got associated.

  - Just for knowledge, Prior to K8s Version 1.24, The creation of Token was through a menifest file like this

  ```
    apiVersion: v1
    kind: Secret
    type: kubernetes.io/service-account-token
    metadata:
      name: jenkins-token
      annotations:
        kubernetes.io/service-account.name: jenkins-sa
  ```

## Internal application Authorisation
- After authenticating, the application must be authorized to perform specific actions. This is done through Kubernetes RBAC.
- Steps to Set Up Authorization:
    - Define a Role or ClusterRole:
    ```
        apiVersion: rbac.authorization.k8s.io/v1
        kind: Role
        metadata:
        namespace: <namespace>
        name: <role-name>
        rules:
        - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list", "watch"]
    ```

- Bind the Role to the Service Account using a RoleBinding:

```
        kubectl create rolebinding <binding-name> \
          --role=<role-name> \
          --serviceaccount=<namespace>:<service-account-name> \
          --namespace=<namespace>
```

- At this point, the application inside the pod can authenticate to the API server using its Service Account token and perform the actions specified in the Role.

- If anyone has further question, who generates the token for the internal users (SA) and how that is used to authenticate. 
- Here is this in more details, 

- Kubernetes Service Account Token (`kubectl create token`)

    - ## What It Is:
        - This token is created by Kubernetes itself.
        - It’s tied to a Kubernetes Service Account and is used for internal authentication within the cluster.

    - ## Who Issues the Token:
        - Kubernetes issues this token for the Service Account, allowing pods or applications inside the cluster to authenticate with the API server.

    - ## How It’s Used:
        - The Service Account token is presented by the application running inside the pod to the API server to authenticate itself.
        - The token is signed by Kubernetes and verified by the API server directly. It does not involve external identity providers like AWS IAM.

---

## External Application/User Authentication

- `Authentication` and Authorization for External Users or Applications
- To authenticate the external user/applcations EKS uses `AWS IAM Authenticator` which is inbuilt to EKS only for authenticating.
- Here, the external user also needs to go through the process of API Server Authentication/Authorisation mechanism.
- But, since the External user are a part of AWS IAM identity, so Kuberetes API server leverages the AWS IAM Autneticator, which validates the user's identity with AWS IAM.

- Lets see - How that works for any application who is already inside the EKS cluster.
### External Application/User Authentication to K8s API Server
- Need to generate the Token for authentication
- The external user or application uses the `AWS CLI` or a library to generate a token for authentication:

## Generating Token for user/application using AWS CLI or Libraries
    `aws eks get-token --cluster-name <cluster-name>`

- This token is included in API requests sent to the Kubernetes API server.
- The API server delegates authentication to the AWS IAM Authenticator, which:
    - Validates the token’s signature using AWS IAM.
    - Confirms the IAM user or role is valid.

## Generating Token for user/application using tools
- Configuration for `Tools` (e.g., Helm, Terraform): 
- In Terraform, the `aws_eks_cluster_auth` data source can be used to generate the token automatically:
```
    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.eks.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.eks.token
      }
    }
```

- If anyone has further question, who generates the token for the external users and how that is used to authenticate. 
- Here is this in more details, 

- IAM-Generated Token (`data.aws_eks_cluster_auth.eks.token`)

    - ## What It Is:
        - This token is generated by AWS IAM tools (like aws eks get-token or Terraform's aws_eks_cluster_auth) to allow external users or applications to authenticate with the Kubernetes API server.

    - ## Who Issues the Token:
        - The AWS IAM Authenticator issues this token.
        - The process works as follows:
            - The client (e.g., Terraform, kubectl) makes a request to generate the token.
            - The IAM credentials (AWS access key, secret key, and session token) of the user or role making the request are validated by AWS IAM.
            - If valid, the IAM Authenticator generates a short-lived token that the client can then use to authenticate to the API server.

    - ## How It’s Used:
        - The token is passed by the client to the Kubernetes API server in the Authorization header of its requests.
        - The API server forwards this token to the AWS IAM Authenticator, which verifies its validity by checking the signature and the associated IAM identity.
        - Once verified, the API server considers the user authenticated.


## External Application/User Authorization: Kubernetes RBAC

- Once authenticated, the external user or application must be authorized to perform actions on the cluster. 
- This involves:

    - Mapping the IAM identity to Kubernetes RBAC using the `aws-auth` ConfigMap or `API-based` authentication mode.

    - Creating Roles and RoleBindings in Kubernetes.

- For example, to grant an external user the ability to list pods:
- Create a `ClusterRole`
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
- Bind the above Role to the user using `clusterrolebinding`

`kubectl create clusterrolebinding <binding-name> --clusterrole=pod-reader --user=<iam-user-arn>`


And this is how the user/applcattion performs their task in Kubernetes either inside or outside the EKS



## What are the different Authentication Modes   in EKS

- EKS supports two authentication modes:

- 1. `ConfigMap Mode`: In this traditional setup, IAM identities (users and roles) are mapped to Kubernetes groups via the aws-auth ConfigMap.
- Example aws-auth ConfigMap: (Its little old style, the new way is to use API )
```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: arn:aws:iam::123456789012:role/EKSWorkerNodeRole
          username: system:node:{{SessionName}}
          groups:
            - system:bootstrappers
            - system:nodes
      mapUsers: |
        - userarn: arn:aws:iam::123456789012:user/JohnDoe
          username: john
          groups:
            - system:masters
```
- Authorization is then managed through RBAC.

- 2. `API-Based` Authentication Mode:

- In this newer approach, authentication and authorization are entirely handled by the Kubernetes API server and AWS IAM without relying on the aws-auth ConfigMap.
- Example Terraform configuration:
```
        resource "aws_eks_cluster" "example" {
          name     = "example-cluster"
          role_arn = aws_iam_role.eks.arn

          vpc_config {
            subnet_ids = var.subnet_ids
          }

          access_config {
            authentication_mode                         = "API"
            bootstrap_cluster_creator_admin_permissions = true
          }
        }
```

## Lets see some possible issues and their troubleshooting approach

- 1. Internal Authentication Issues
- Verify the Service Account token is correctly mounted in the pod.
- Check the RoleBinding or ClusterRoleBinding for the Service Account.

- 2. External Authentication Issues
- Ensure the IAM identity is mapped in the aws-auth ConfigMap (for config_map mode) or has proper IAM policies (for API mode).
- Use the kubectl auth can-i command to test permissions:

    `kubectl auth can-i list pods` or for broad `kubectl auth can-i "*" "*"`

- 3. General Debugging
- Review API server logs for authentication or authorization errors.
- Check IAM policies and Kubernetes RBAC bindings.
