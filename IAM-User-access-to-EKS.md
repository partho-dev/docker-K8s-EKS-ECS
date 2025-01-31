> ## How to give access to IAM users/Groups to EKS cluster (EKS RBAC)

## Managing EKS Access Using `aws_eks_access_entry` with IAM Roles and Policies

- ![iam-group-rbac](https://github.com/user-attachments/assets/e26263d5-cbb2-4e56-9443-e5be39b0c6a6)

> Full process in one image
- ![K8sRBAC](https://github.com/user-attachments/assets/3fbd1eeb-d733-47ff-b00b-03e7124f3416)


- Amazon EKS (Elastic Kubernetes Service) is a managed Kubernetes service that makes it easy to deploy, manage, and scale containerized applications. 
- Managing user access to an EKS cluster often involves configuring IAM roles and policies.

## Setting up an EKS Cluster on AWS
Lets setup an EKS access using 

* Terraform, 
* `aws_eks_access_entry`, not using depricated `aws-auth` method
* IAM roles, and policies 

### Planning the IAM 
- We’ll create an `admin group` with full access to the EKS cluster through IAM policy, 
- assign `IAM users` to that `group`, 
- and `assume roles` (`Trust Policy`) to manage access.

### Prerequisites:

- Basic understanding of AWS IAM and Kubernetes RBAC (Role-Based Access Control).
- an AWS IAM user which would be used to create the EKS cluster
- AWS CLI configured using the above user on laptop (`aws configure --profile "some_name"`)
- Terraform installed.
- `kubectl` installed 
- eksctl installed (optional) [we are going to create eks using tf, not through eksctl]


> Step 1: Setting Up Your Terraform Configuration

- We'll start by setting up the necessary AWS IAM group, roles, policies, and EKS access using Terraform.

- 1.1. Provider Configuration

The provider configuration tells Terraform which AWS profile and region to use. Make sure the profile you’re using has sufficient permissions to manage IAM and EKS resources.
```
provider "aws" {
  region  = "us-east-1"
  profile = "test-eks"
}

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
```

- 1.2. Get Cluster and Caller Info

- Use data sources to retrieve the EKS cluster details and the current AWS account ID.

```
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "main" {
  name = "your-eks-cluster-name"
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}
```

> Step 2: Create IAM Group, Role, and Policies

- We’ll create an IAM group for admins, a role that allows the group to assume EKS access, and policies that provide full access to EKS.


2.1. Create Admin IAM Group

We create an IAM group named admin-group which will contain the users that need EKS admin access.

```
resource "aws_iam_group" "admin_group" {
  name = "admin-group"
}
```

2.2. Create Admin Role for the Group

The role allows users in the admin-group to assume EKS admin permissions. The assume role policy allows any user in the AWS account to assume this role.

```
resource "aws_iam_role" "adminGroupRole" {
  name = "adminGroupRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }
  ]
}
POLICY
}
```

2.3. Create Admin Policy for Full Access to AWS Resources

Here, we define a custom policy with full access to all AWS resources. This is applied to the role that the group will assume.

```
resource "aws_iam_policy" "adminPolicy" {
  name        = "adminPolicy"
  description = "Full access to all resources, including EKS"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}
```

2.4. Attach Policies to Group and Role

We now attach the full access policy to the IAM group and the role.

```
resource "aws_iam_group_policy_attachment" "attach_admin_policy_to_group" {
  group      = aws_iam_group.admin_group.name
  policy_arn = aws_iam_policy.adminPolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach_admin_policy_to_role" {
  role       = aws_iam_role.adminGroupRole.name
  policy_arn = aws_iam_policy.adminPolicy.arn

  depends_on = [
    aws_iam_policy.adminPolicy,
    aws_iam_role.adminGroupRole
  ]
}
```

Step 3: Set Up EKS Access Using aws_eks_access_entry

The aws_eks_access_entry resource will link the IAM role created earlier to the EKS cluster, granting Kubernetes admin permissions to members of the admin-group.
```
resource "aws_eks_access_entry" "admin" {
  cluster_name      = data.aws_eks_cluster.main.name
  principal_arn     = aws_iam_role.adminGroupRole.arn
  kubernetes_groups = ["Admin-Group"]
  type              = "STANDARD"
}
```

Step 4: Create IAM User and Assign to Admin Group

Next, we create a user and add it to the admin-group.
```
resource "aws_iam_user" "partho_admin_1" {
  name = "partho-admin-1"
}

resource "aws_iam_user_group_membership" "admin_group_membership" {
  user   = aws_iam_user.partho_admin_1.name
  groups = [aws_iam_group.admin_group.name]
}
```

Step 5: Cluster Role Binding for Kubernetes Access

The final step is to create a ClusterRoleBinding to map the Kubernetes group (Admin-Group) to the Kubernetes cluster-admin role. This grants full Kubernetes access to users in the admin group.

Create a YAML file, clusterrolebinding.yaml, with the following content:
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: Admin-Group
  apiGroup: rbac.authorization.k8s.io
```

Apply the ClusterRoleBinding in your Kubernetes cluster:
```
kubectl apply -f clusterrolebinding.yaml
```

- Then test if the profile is able to  assume temporary token
`aws sts assume-role --role-arn arn:aws:iam::08146294:role/<RoleName> --role-session-name partho-session --profile partho-user`


Step 6: Update Kubeconfig and Test Access

After setting everything up, you need to update your kubeconfig to use the IAM role:

- Create an AWS profile in `~/.aws/config` for the role assumption:
```
[profile admin-role]
role_arn = arn:aws:iam::123456789012:role/adminGroupRole
source_profile = default
region = us-east-1
```

Update kubeconfig using the new profile:
```
aws eks --region us-east-1 update-kubeconfig --name your-eks-cluster --profile admin-role
```

Test Access by running a command like:
- `kubectl auth can-i "*" "*"`
- `kubectl get pods`

