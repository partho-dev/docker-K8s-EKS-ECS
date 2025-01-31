## EKS got 3 nodes(Ec2 server) attached automatically only for 4 applications?
- So the cost to run 4 application is high. 
- We need to see if the resources are underutilised

### What to check?

- 1. First check the nodes on the EKS
- `kubectl get nodes`
```
kubectl get nodes

NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-1-212.ec2.internal   Ready    <none>   63d   v1.31.0-eks-a737599
ip-10-0-2-169.ec2.internal   Ready    <none>   63d   v1.31.0-eks-a737599
ip-10-0-2-43.ec2.internal    Ready    <none>   55d   v1.31.0-eks-a737599
```

- 2. Check the `Resource` Utilisation per nodes(Ec2 server) 
- `kubectl top nodes`
```
kubectl top nodes

NAME                         CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
ip-10-0-1-212.ec2.internal   34m          1%     4277Mi          59%
ip-10-0-2-169.ec2.internal   52m          2%     2828Mi          39%
ip-10-0-2-43.ec2.internal    41m          2%     3187Mi          44%

```
- The values  for `CPU` are reported in millicores (m), where `1000m` equals `1 full CPU core`.
- Here, the instance is `M5 Large` - which has close to `8GB` of RAM, so the nodes have used close to `4GB` RAM to support the applications hosted on that server   or node

Observation : 
- CPU Usage: The nodes are underutilized in terms of CPU; the applications are consuming a `very small fraction` of the available CPU capacity.

- Memory Usage: Memory utilization is significant (~40%-60% across the nodes). This suggests the applications or system-level processes (e.g - Kubernetes daemons, logging, monitoring) are consuming a lot of memory.

- 3. Check the resource utilisation of Individual `PODS` on the cluster for all Namespaces
- `kubectl top pods -A`
```
NAMESPACE        NAME                                                 CPU(cores)   MEMORY(bytes)
argocd           argocd-application-controller-75df794775-ww74t       11m          108Mi
argocd           argocd-dex-server-6f9d74987f-thvdn                   1m           25Mi
argocd           argocd-redis-b8c96fbf5-7qlwx                         1m           2Mi
argocd           argocd-repo-server-dbcbcbf55-94kww                   1m           75Mi
argocd           argocd-server-68ddd59568-qhsvd                       2m           39Mi
cert-manager     cert-manager-654c77dd55-q854t                        1m           26Mi
cert-manager     cert-manager-cainjector-6498546c9f-h7jcd             1m           29Mi
cert-manager     cert-manager-webhook-6689564869-7bxrt                1m           11Mi
erg-ns-jenkins   jenkins-deployment-65c9c7bcfb-7kj6d                  2m           1339Mi
erg-ns-nexus     nexus-deployment-5c55f486c4-trvm7                    4m           3348Mi
erg-ns-sonar     sonarqube-deployment-58c99b5f86-krz58                6m           1947Mi
ingress          external-ingress-nginx-controller-54bf9546c5-ntptr   2m           49Mi
kube-system      autoscaler-aws-cluster-autoscaler-58c8bf9c77-6lzcn   1m           34Mi
kube-system      aws-load-balancer-controller-6d985cfb5d-4jrk8        2m           27Mi
kube-system      aws-load-balancer-controller-6d985cfb5d-msfxt        1m           23Mi
kube-system      aws-node-2npz5                                       3m           66Mi
kube-system      aws-node-7pbsp                                       3m           58Mi
kube-system      aws-node-9tmnx                                       3m           63Mi
kube-system      coredns-789f8477df-dd9pv                             1m           15Mi
kube-system      coredns-789f8477df-mx4rx                             2m           15Mi
kube-system      ebs-csi-controller-57b48f8f59-dntf5                  3m           66Mi
kube-system      ebs-csi-controller-57b48f8f59-p8l6c                  2m           52Mi
kube-system      ebs-csi-node-4x7rx                                   1m           20Mi
kube-system      ebs-csi-node-9ffz9                                   1m           22Mi
kube-system      ebs-csi-node-mcztp                                   1m           24Mi
kube-system      efs-csi-controller-7685cb7758-l4k7t                  2m           49Mi
kube-system      efs-csi-controller-7685cb7758-rszt8                  2m           50Mi
kube-system      efs-csi-node-677kt                                   7m           71Mi
kube-system      efs-csi-node-6wzf4                                   7m           192Mi
kube-system      efs-csi-node-l8tpb                                   7m           67Mi
kube-system      eks-pod-identity-agent-8twqn                         1m           6Mi
kube-system      eks-pod-identity-agent-k4286                         1m           5Mi
kube-system      eks-pod-identity-agent-lrn9j                         1m           7Mi
kube-system      kube-proxy-jrzxk                                     1m           18Mi
kube-system      kube-proxy-tl2gj                                     1m           17Mi
kube-system      kube-proxy-vt6gp                                     1m           13Mi
kube-system      metrics-server-58f4fbc584-btvwn                      3m           22Mi
```

- Here, we see few of the PODs like `efs-csi-node-6wzf4` `Jenkins`, `Nexus`, `SOnarQube` are consuming more memory
