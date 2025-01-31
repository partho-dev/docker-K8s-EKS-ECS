># <mark>How to add external cluster on argo for deployment </mark>

---
- By Default, the argo adds the same cluster 
- <img width="1677" alt="default-cluster" src="https://github.com/user-attachments/assets/e0eb1cbe-c2df-4ed4-96a0-08100754b7d1">

---
## How to add other kubernetes into ArgoCD Cluster list
- <mark>1.</mark> Add the new cluster on the local laptop kubeconfig context
- ` aws eks update-kubeconfig --region us-east-1 --name eks-app-dev --profile app-dev`

- <mark>2. </mark>  install ArgoCD cli on your local laptop(If its not installed 
- For windows, we can use `choco install argocd-cli --version=2.6.4`)

- <mark>3. </mark> Login to ArgoCD Server (use the url without https://) 
`argocd login argo.domain.net --username admin`
- <mark>4. </mark> add the new cluster into the argo 
`argocd cluster add arn:aws:2019:cluster/eks-app-dev --name app-dev --upsert`

- <img width="1677" alt="new-cluster" src="https://github.com/user-attachments/assets/c25abc6d-848c-4f7a-9d27-588849ad9697">


---

> List the cluster 
- `argocd cluster list`

