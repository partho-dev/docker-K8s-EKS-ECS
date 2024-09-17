## Setup EKS cluster on AWS

- **Prerequisite**
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
```
macbook@MacBooks-MacBook-Pro ~ % eksctl get clusters --profile customer-infra-dev
NAME		REGION		EKSCTL CREATED
demo-eks	ap-south-1	True
```
- To see other info like nodegroup etc, need to set the cluster name `--cluster cluster-name`
- `get nodegroup --cluster demo-eks --profile customer-infra-dev`


### Delete EKS Cluster
- `eksctl delete cluster --name demo-eks --region ap-south-1 --profile customer-infra-dev`

### Steps to Configure kubectl for Your EKS Cluster:
- Now, need to configure the `kubectl` to see the `eks`
- Use `eksctl` to Update `kubectl Context`
- `eksctl utils write-kubeconfig --cluster <cluster-name> --profile customer-infra-dev`

- Verify the new context - `kubectl config get-contexts`
- switch the context between minikube & eks - `kubectl config use-context <eks-cluster-context-name>`

- Test if the `kubectl` able to get the eks - `kubectl get nodes`

- list all available clusters using - `kubectl config get-clusters`




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

- `--ssh-access --ssh-public-key my-key-pair`: This flag enables SSH access to your worker nodes and associates the specified SSH key (my-key-pair.pem) with the instances so you can SSH into them if needed.

- `--vpc-private-subnets and --vpc-public-subnets`: This allows you to specify custom subnets for the VPC. In production, you’ll likely have dedicated public and private subnets for different workloads.

- `--nodes-min, --nodes-max`: These options enable autoscaling for the worker nodes.

- `--enable-ssm`: This enables AWS Systems Manager (SSM), which allows you to access and manage your EC2 instances without needing direct SSH access. It is a more secure and modern approach.