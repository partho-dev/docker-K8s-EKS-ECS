> # ArgoCD on EKS with Terraform & Helm

Hey there! 👋 If you’re here, you’re probably ready to bring GitOps magic into your Kubernetes world with ArgoCD. We’re about to take this step-by-step, from setting up ArgoCD on an EKS cluster, right down to exposing it through an Ingress so you can access the UI in style.

Let's get started with an analogy: imagine you’re installing an app (like Calculator) on your laptop. First, you download it, then install it, and finally start using it. Similarly, installing ArgoCD in an EKS cluster means connecting to the cluster, deploying ArgoCD, and configuring it to meet our needs (like external access). We'll be using Helm and Terraform to automate the entire process.
📦 Pre-reqs

Make sure you’ve got the following ready:

- A Kubernetes cluster on EKS
- AWS CLI set up
- kubectl installed and connected to your cluster
- Terraform and Helm installed

---

**Ready? Let’s go!** 🏃‍♂️ 
- Create a tf project with below resources in the sequence of steps
# Step 1: Get Access to the EKS Cluster

First, we need to authenticate our Helm client with the EKS cluster. Using Terraform, we’ll set up AWS resources to retrieve the EKS endpoint, CA certificate, and token for authentication.

###  1️⃣ Get the EKS cluster data

```
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}
```

### 2️⃣ Configure the Helm provider to connect to EKS

```
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

```

### Here’s what’s happening:

- aws_eks_cluster: Gets details like the endpoint and CA certificate from your EKS cluster.
- aws_eks_cluster_auth: Generates an authentication token.
- helm provider: Configures Helm to use the endpoint, token, and CA for secure access to EKS.

Now, authentication is a go ✅


# Step 2: Install ArgoCD with Helm

Next, let’s install ArgoCD using the Helm chart provided by Argo’s official Helm repository. We’ll specify some key settings: the chart name, namespace, and version.

### 3️⃣ Helm release for ArgoCD
```
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  version    = "3.35.4"
}
```

### In the above:

- repository: Points to the source of the ArgoCD Helm chart.
- namespace: Defines where ArgoCD will live in your EKS cluster (we created the namespace argocd).
- version: Sets the chart version to ensure compatibility.

So far, so good! But we want to access ArgoCD externally—let’s set up Ingress next.

---

# Step 3: Configure Ingress in values.yaml for External Access

Now, let’s make sure ArgoCD can be accessed from outside the cluster. We’ll do this by defining Ingress settings in values.yaml, which is like a “settings file” Helm reads during installation. Here’s an example that includes the Ingress configurations.

- Create a `values.yaml` file with the following content:


```
# values.yaml for ArgoCD
global:
  image:
    tag: "v2.6.6"

server:
  extraArgs:
    - --insecure  # Prevents ArgoCD server from enforcing HTTPS internally
    # - --rootpath=/

  ingress:
    enabled: true
    ingressClassName: "external-nginx"
    annotations:
      cert-manager.io/cluster-issuer: http-01-production
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: 100m
      nginx.ingress.kubernetes.io/proxy-buffering: "off"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
      nginx.ingress.kubernetes.io/use-regex: "true"
    hosts:
      - argo.domain.net
    paths:
      - /
    pathType: Prefix
    tls:
      - secretName: argo-domain-net
        hosts:
          - argo.domain.net
  ```

  - ingressClassName: external-nginx defines which Ingress controller to use.
  - annotations: Set things like force SSL redirection and custom timeout values.
  - hosts: Defines the domain (argo.lia.com) you want to use to access ArgoCD.
  - tls: Enables TLS and links to a TLS secret (argo-lia-net) managed by cert-manager.


### Add this file in the Helm release on step `3`
`values = [file("values.yaml")]`

```
resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"

  values = [file("argo_values.yaml")]
}
```
# Step 4: Point the Domain to the Ingress Controller

Once ArgoCD is deployed, update your DNS records to point argo.lia.com to the IP or DNS name of the Ingress controller. This will let you access ArgoCD from your browser!
Step 5: Verify Installation

Time for the moment of truth! Let’s check if everything went smoothly:

bash

# Check if ArgoCD is installed
- `helm list -A`

You should see argocd listed. 🎉

# Step 6: Check ArgoCD Pods

Make sure the ArgoCD pods are up and running: `kubectl get pods -n argocd`

If all’s well, you’ll see the pods running in the argocd namespace. 🚀

# Step 7: Retrieve Admin Password

To log in to ArgoCD, retrieve the initial admin password. This password is stored in the argocd-initial-admin-secret.

```
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

Now, take this password and head to the ArgoCD UI at https://argo.lia.com to log in!

# Step 8: Optional - Port Forwarding for Local Testing

Want to test on your local machine? Use kubectl port-forwarding to access ArgoCD locally:
```
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Now you can visit http://localhost:8080 to view the ArgoCD UI on your local machine!
🎉 And That’s It!

You’ve now:

    Set up a connection to EKS.
    Installed ArgoCD using Helm via Terraform.
    Configured Ingress to access ArgoCD through your custom domain.
    Verified installation and accessed the UI.

Wrapping Up

With this guide, you’ve got the power of GitOps through ArgoCD deployed on EKS, all managed in a clean and reproducible way via Terraform and Helm. Now you’re ready to deploy applications like a pro—happy GitOps-ing!
