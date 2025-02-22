# EFS as CSI Strage for EKS


- ![aws-efs-kubernetes-ec2](https://github.com/user-attachments/assets/c4170417-c615-4acf-8272-29e8597e3406)

## Understanding AWS EFS (Elastic File System)

- AWS EFS is a fully managed, serverless, elastic file storage service that can be mounted by multiple EC2 instances or Kubernetes pods simultaneously, enabling shared access across nodes.

### EFS Architecture and Key Components

  - EFS File System:
  - The core storage resource resides within a VPC.

    `Mount Targets`:
    These serve as endpoints for EFS within each Availability Zone (AZ). Each mount target is associated with a private subnet in the VPC.
    `Traffic to EFS Mount Targets`:
      - Uses NFS protocol on port 2049.
      - Security Groups for the mount target must allow incoming traffic on this port from the source node's security group.

    `Source`:
      - EC2 instances or EKS worker nodes (pods).
      - These source nodes reside in private subnets within the VPC.

### EFS Usage with EC2

- To mount EFS with an EC2 instance:

    - Install EFS Utilities: Install the amazon-efs-utils package on the EC2 instance.

    - Create Mount Point on EC2: `mkdir /mnt/efs`

- Mount the EFS File System: Use the EFS DNS name or mount target IP.
Example:
```
sudo mount -t efs -o tls fs-<file-system-id>:/ /mnt/efs
```

- Verify the Mount:
```
    df -h
```

### EFS Usage with EKS

- AWS EFS can be integrated with EKS to provide shared storage for Kubernetes pods. 
- This involves the EFS CSI (Container Storage Interface) Driver, which manages EFS integration at the node level.
- Steps for Integration:

  - Provision EFS and Mount Targets:
      - Use Terraform or AWS Console to create the EFS file system and mount targets.
      - Example Terraform code for mount targets:
```
    resource "aws_efs_mount_target" "zone_a" {
      file_system_id  = aws_efs_file_system.eks.id
      subnet_id       = aws_subnet.private_zone1.id
      security_groups = [aws_security_group.eks_node_sg.id]
    }
```
- Install the EFS CSI Driver:

    - Use Helm to deploy the EFS CSI Driver to the Kubernetes cluster.
    Example:
```
    helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
    helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
      --namespace kube-system
```
- Create a StorageClass:

  - Define a Kubernetes StorageClass to provision volumes using EFS.
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs
provisioner: efs.csi.aws.com
```
- Create a PersistentVolumeClaim (`PVC`):

  - Pods use PVCs to request storage.
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nexus-pvc-efs
  namespace: ns-nexus
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  storageClassName: efs
```
- Mount the PVC to Pods:

  - Define a volume in the pod's manifest to use the PVC.
  ```
    volumes:
      - name: efs-storage
        persistentVolumeClaim:
          claimName: nexus-pvc-efs
  ```
### Troubleshooting Common Issues
>  Issue 1: PVC Capacity Mismatch

  - PVC may show a smaller capacity than requested. This happens because EFS ignores the storage value and provides the entire filesystem. 
  - Verify this by checking the EFS directory's actual usage.

> Issue 2: Mount Errors

  - Log example:
  ```
    Could not start amazon-efs-mount-watchdog, unrecognized init system "aws-efs-csi-dri"
  ```
  - Possible Causes:
      - EFS utilities are missing or not functioning in the CSI driver pod.
      - Security Group rules for the mount target are misconfigured.
      - Solution: Verify that port `2049` is open in the mount target's SG and is accessible from the worker node's SG.
      - Ensure the EFS CSI Driver is correctly installed.

> Issue 3: Identifying Pods Managed by efs-csi-node-*

  - Each efs-csi-node-* pod handles mounts for all pods on its associated worker node. To identify pods using PVCs managed by a specific efs-csi-node-* pod:
  ```
    kubectl get pods -o wide --field-selector spec.nodeName=<node-name>
    kubectl describe pod <pod-name> | grep persistentVolumeClaim
  ```

### Observability: 
- To know How many Nodes are there in the Cluster
```
kubectl get nodes 
kubectl get nodes -o wide
```
- To know which node of the EKS is consuming how much resource (CPU/RAM)
 ```
 kubectl top nodes  
 kubectl top nodes
NAME                                    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
ip-10-0-1-212.ec2.internal   39m             2%        4240Mi                   59%

```

- Now, we got to know the node(Ec2 server) from above it shows it already used` 59% `of total memory
- But, to know what are the actual pods living in that node (pod in a node)
```
kubectl get pods -o wide --all-namespaces --field-selector spec.nodeName=ip-10-0-1-212.ec2.internal

NAMESPACE      NAME                       READY   STATUS    RESTARTS      AGE   IP                    NODE                        
argocd              argocd-dex-server     1/1        Running   0                     47d   10.0.1.128   ip-10-0-1-212.ec2.internal   
ns-nexus   nexus-deploymen     1/1         Running   0                    63d   10.0.1.243   ip-10-0-1-212.ec2.internal   
```


- To know which pod is using pvc and what is the pvc usage
`kubectl describe pod nexus-deployment-5c55f486c4-trvm7 -n ns-nexus | grep -A5 Volumes`
- Verify PVC bound to EFS : `kubectl describe pvc nexus-pvc-efs -n ns-nexus`
