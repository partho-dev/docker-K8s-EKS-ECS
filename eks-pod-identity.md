
# Understanding Pod Identity in EKS

- If you're running applications on AWS EKS and want your pods to communicate with AWS services like S3, Lambda, or RDS, you can't directly assign an IAM role to a pod like you would for AWS services. Instead, you need a solution that allows pods to assume roles, and that's where Pod Identity comes into play.

- `Pod Identity` allows you to securely provide AWS credentials to your applications running in Kubernetes by associating an IAM role with a Kubernetes Service Account (SA). Here's how it works and how you can set it up.
Why Do We Need Pod Identity?

- Kubernetes pods don’t natively have a way to communicate securely with AWS services using IAM roles. This is a challenge because you don’t want to hardcode AWS credentials in your pod, and using access keys can expose security vulnerabilities.

- In AWS, IAM roles provide permissions for one service to interact with another securely. But when using Kubernetes, things change. EKS clusters run your pods, but you can’t just attach IAM roles to pods. Instead, we rely on Pod Identity, which works by associating an IAM role with a service account (SA) in a namespace.
The Pod Identity Workflow

  - Create an IAM Role with Pod Service Principal: You create an IAM role that uses a special service principal, pod.eks.amazonaws.com, to allow your pod to assume that role.
  - `Create a Service Account (SA)`: In Kubernetes, each pod can be linked to a Service Account. This SA is associated with the IAM role.
  - `Pod Identity Controller`: You install a controller in your EKS cluster that manages this association and ensures your pod is allowed to assume the role.

# Pod Identity in Action

Let's dive into some code to understand how this is done.
> `Step 1`: Create the IAM Role for Your Pod

- First, create an IAM role that allows your pod to access a specific AWS service, for example, S3.

# Create an IAM policy document
```
data "aws_iam_policy_document" "s3_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
```

# Create an IAM role for accessing S3
```
resource "aws_iam_role" "nginx_s3_role" {
  name               = "nginx-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role_policy.json
}
```
# Attach a policy to the role to allow S3 access
```
resource "aws_iam_role_policy_attachment" "nginx_s3_access" {
  role       = aws_iam_role.nginx_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
```
- In the policy document, we specify that the role can be assumed by pods.eks.amazonaws.com — this is the core of pod identity. It ensures that only Kubernetes pods can assume this role.

> `Step 2`: Create the Kubernetes Service Account (SA)
- Next, create a Kubernetes Service Account (SA), which the pod will use. This SA will be associated with the IAM role created above.

# nginx-sa.yaml
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-sa
  namespace: nginx
```

- Once the SA is created, we associate the IAM role with this service account using Terraform's aws_eks_pod_identity_association.
> `Step 3`: Associate the IAM Role with the Service Account

- We need to associate the role we created with the Service Account in the nginx namespace using the following code:

# Pod Identity Association between the IAM role and the service account

```
resource "aws_eks_pod_identity_association" "nginx_s3_association" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "nginx"
  service_account = "nginx-sa"
  role_arn        = aws_iam_role.nginx_s3_role.arn
}
```

- This step is crucial: it tells the Pod Identity Controller to manage the role and service account association. It ensures that when a pod uses the nginx-sa service account, it can assume the nginx-s3-access-role IAM role and get the necessary permissions to access S3.
Installing the Pod Identity Controller

- You might wonder: does EKS come pre-installed with Pod Identity? No, you need to install it as an add-on. The Pod Identity controller watches for the IAM roles associated with Kubernetes Service Accounts and manages the permissions for the pods.

- Here's how you install it using eksctl:
```
eksctl utils associate-iam-oidc-provider \
  --region <region> \
  --cluster <cluster_name> \
  --approve
```

- Then, install the Pod Identity Webhook and the IAM Role service using Helm:
```
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system
```

- Testing the Pod Identity
Once the setup is done, let's test the pod identity by deploying an nginx pod and accessing S3.
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx
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
      serviceAccountName: nginx-sa  # Using our service account
      containers:
      - name: nginx
        image: nginx
```

- After deploying the pod, you can enter the pod and test the S3 access.
```
kubectl exec -it <nginx-pod> -n nginx -- /bin/sh
aws s3 ls s3://your-bucket
```

- If the pod identity is working correctly, you should be able to list the S3 bucket contents directly from within the pod.
How to Check the Service Account Role Association

- To check how the roles or permissions are assigned to the Service Account, you can inspect it using:

- `kubectl get sa nginx-sa -n nginx -o yaml`

- This command will show the annotations on the service account, which should include the ARN of the IAM role.
Summary


Key points:

    IAM Role for Pods: Create an IAM role that pods can assume.
    Service Account Association: Associate the role with a Kubernetes Service Account.
    Pod Identity Controller: Ensure the controller is installed to manage the IAM role assignments.