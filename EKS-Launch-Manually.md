# <mark> Setup EKS cluster on AWS </mark>

## Lauch EKS manually through AWS Console
---
### What are needed to lauch EKS
> **Create Two IAM Role**
- IAM for EKS Control Plane (`EKS-Control-Role`)
- Policies  - 
  - `AmazonEKSClusterPolicy` & 
  - `AmazonEKSServicePolicy`
  - `aws eks --region <region> update-kubeconfig --name <cluster-name>` => for CloudWatch logs access and other AWS services integration.
  

<img width="1332" alt="eks-IAM-ControlPlne" src="https://github.com/user-attachments/assets/56c368e8-8a4d-431d-8f10-0581e37fe46f">

- IAM for EKS Worker Node (`EKS-Nodes-Role`)
- Policies 
- `AmazonEC2ContainerRegistryReadOnly` - Grants read-only access to ECR for pulling container images.
- `AmazonEKSWorkerNodePolicy` - Grants permissions to worker nodes to communicate with the EKS control plane.
- `AmazonEKS_CNI_Policy` - Required for the networking (CNI) plugin to manage pod networking
- `CloudWatchAgentServerPolicy` - amazon CloudWatch for logging

<img width="1312" alt="eks-IAM-WorkerNode" src="https://github.com/user-attachments/assets/98fa9fd5-d6d2-46a9-ba3f-0c7515135ca5">

> **VPC setup**

- Creation of VPC with all necessary components
  - private subnet & its tag
    - `kubernetes.io/role/internal-elb 1`
  - public subnet & its tag 
    - `kubernetes.io/role/elb 1`
  - NAT Gateway placed on public subnet and directing private subnet traffic to internet through it
  - Security Group
  - <https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml>
  - and use the private/public CF template - <https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml>



- Manual Creation of VPC for EKS
- Create a VPC with two subnets:

- `Public Subnet`: This is typically for the load balancers 
- `Private Subnet`: This is where the worker nodes (EC2 instances) will reside. The control plane will access the nodes securely in this private subnet.

>  **NAT Gateway**
- If the worker nodes need outbound internet access (e.g., to pull Docker images from ECR or other external repos).

<img width="1394" alt="eks-vpc" src="https://github.com/user-attachments/assets/b176630f-b85c-49db-bb38-6beadab6a045">

> subnet and their special tags

- Public Subnets: Must have the following tags:
```
    kubernetes.io/cluster/<cluster-name> = shared
    kubernetes.io/role/elb = 1
```
- Private Subnets: Must have the following tags:
```
    kubernetes.io/cluster/<cluster-name> = shared
    kubernetes.io/role/internal-elb = 1
```
> Example of subnets and its tags through TF
```
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = "EKS-VPC"
  cidr = var.vpc_cidr[0]

  azs             = data.aws_availability_zones.az.names
  private_subnets = var.priv_sub[*]
  public_subnets  = var.pub_sub[*]

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    Terraform                           = "true"
    Environment                         = "test"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

```

---

> **Security Groups**
- `Control Plane`: EKS Control Plane communicates securely over HTTPS with the worker nodes, so the security groups should allow inbound access from the worker node security group on port 443.

- <img width="1393" alt="control-SG" src="https://github.com/user-attachments/assets/da622a76-de03-4812-a1f7-e51ac91c03ad">


- `Node SG`: Allow inbound communication from the Control Plane Security Group on port 443 (HTTPS).
- Allow inbound SSH access (`port 22`) from admin IP (or trusted IP range)to SSH into the nodes.

---

### Creation on EKS cluster manually
- Create cluster and select 
  - subnet (both private & public)
  - select the SG (control-plane SG)
  - EKS cluster creation would be done

- Under comput, create nodegroup
  - select only private subnet
  - select the SG for worker-SG


> Additional Considerations

- `Worker Nodes Communication`: Allow inbound traffic on ports `10250` and `443` for `Kubelet communication` (node management) and the Kubernetes API.
- `Pod Networking`: For CNI (like AWS VPC CNI), we need to allow necessary port ranges for pod-to-pod communication across nodes (e.g., 1025-65535 for ephemeral ports).

> Additional Points:
- Cluster Autoscaler - If the autoscaling is needed for worker nodes, configure the `Cluster Autoscaler` with the appropriate IAM policies and roles.

- Logging: By default, EKS doesn’t enable logging. So need to configure CloudWatch logging for the control plane logs during the creation process. This helps with debugging and monitoring.

- kubectl Configuration: After the EKS cluster is launched, The local system should have communication with EKS, so need to set that on kubeconfig

```
aws eks --region <region> update-kubeconfig --name <cluster-name>
```

```
eksctl utils write-kubeconfig --cluster eks-partho
```

- <img width="720" alt="setup-eks-local" src="https://github.com/user-attachments/assets/44d4e1e9-872f-4857-9251-049429265469">



- Node IAM Role: The worker node IAM role is assigned to the node group when the node is launched, either manually or via a managed node group.


**Prerequisite**
- aws cli is installed on your laptop
- completed the aws configure and set the aws IAM user access/secret on laptop (~/.aws/credentials)
    - `aws configure --profile customer-infra-dev`
- eksctl is installed
- kubectl is installed

### Creation of EKS Cluster through command promot - eksctl
- make sure aws creds are set 

- check that - ` aws sts get-caller-identity --profile customer-infra-dev`

- Then create the cluster - `eksctl create cluster --name demo-eks --region ap-south-1 --nodegroup-name my-nodes --node-type t3.small --managed --nodes 2`

- Then check if the cluster is created (wait for 20 mons)

- `eksctl get cluster --profile customer-infra-dev`

- Delete the eks cluster using `eksctl delete` command
```
eksctl delete cluster --name partho-eks --region ap-south-1
```

```
macbook@MacBooks-MacBook-Pro ~ % eksctl get clusters --profile customer-infra-dev
NAME		REGION		EKSCTL CREATED
demo-eks	ap-south-1	True
```

- To see other info like nodegroup etc, need to set the cluster name `--cluster cluster-name`
- `get nodegroup --cluster demo-eks --profile customer-infra-dev`


### Delete EKS Cluster
```
eksctl delete cluster --name demo-eks --region ap-south-1 --profile customer-infra-dev
```

### Steps to Configure kubectl for Your EKS Cluster:
* Now, need to configure the `kubectl` to see the `eks`

- Use `eksctl` to Update `kubectl Context`

```
eksctl utils write-kubeconfig --cluster <cluster-name> --profile customer-infra-dev
```
- or using AWS Cli also we can add the new cluster in our context
```
aws eks --region ap-south-1 update-kubeconfig --name my-cluster --profile customer-infra-dev
```

- Verify the new context - `kubectl config get-contexts`

- switch the context between minikube & eks 
```
kubectl config use-context <eks-cluster-context-name>
```

- Test if the `kubectl` able to get the eks 

```
kubectl get nodes
```

> ## Steps to remove the cluster from .kube/config file
```
- kubectl config get-contexts
- kubectl config delete-context customer-infra-dev@my-cluster
- kubectl config unset clusters.my-cluster
- kubectl config unset users.customer-infra-dev
```

- list all available clusters using

```
kubectl config get-clusters
```




### Production grade EKS
- The above is a simple EKS cluster creation, which does not have any security
- To make a standard EKS, there are few components needed

```
eksctl create cluster \
  --name demo-eks \
  --region ap-south-1 \
  --nodegroup-name my-nodes \
  --node-type t3.small \
  --managed \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --ssh-access \
  --ssh-public-key my-key-pair \
  --vpc-private-subnets subnet-0123456789abcdef0,subnet-0abcdef0123456789 \
  --vpc-public-subnets subnet-1234567890abcdef0,subnet-abcdef01234567890 \
  --enable-ssm \
  --profile customer-infra-dev
```

### Explanation of Additional Flags:

- `--ssh-access --ssh-public-key my-key-pair`: This flag enables SSH access to the worker nodes and associates the specified SSH key (my-key-pair.pem) with the instances to SSH into them if needed.

- `--vpc-private-subnets and --vpc-public-subnets`: This allows to specify custom subnets for the VPC. In production,

- `--nodes-min, --nodes-max`: These options enable autoscaling for the worker nodes.

- `--enable-ssm`: This enables AWS Systems Manager (SSM), which allows to access and manage EC2 instances without needing direct SSH access. It is a more secure and modern approach.



> ## <mark>Configure local system to work with EKS Cluster</mark>

1. Configure AWS Profile:
```
aws configure --profile customer-infra-dev
```

2. Add EKS Cluster to kubeconfig:
```
aws eks --region ap-south-1 update-kubeconfig --name my-cluster --profile customer-infra-dev
```

3. Verify Access to EKS Cluster:

```
kubectl get nodes
```

4.  Switch to the EKS Context:
```
kubectl config use-context arn:aws:eks:ap-south-1:<account-id>:cluster/my-cluster
```


## What will happen if the connection to node is timing out

- Check the cluster endpoint access - `aws eks describe-cluster --name my-infra-eks --region us-east-1 --query 'cluster.resourcesVpcConfig' `
if the output is 
```
    "endpointPublicAccess": false,
    "endpointPrivateAccess": true,
```
- The public access from your laptop to EKS is not possible.
- For that, need
    - Create a VPN connection to the EKS VPN and connect from laptop through that VPN
    - use a bastion host on public subnet of the EKS VPN
    - install eksctl, kubectl and use the bastion server to perform all K8s administartions
    - else - update the eks cluster to be accessible publicly `cluster_endpoint_public_access = true`
    