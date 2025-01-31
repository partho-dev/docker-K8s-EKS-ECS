> # Kubernetes Storage: How to handle the persistant storage for dynamic pods
---

### This guide provides a detailed explanation of storage concepts in Kubernetes (K8s) by drawing comparisons to EC2, Docker, and traditional systems. It explains how Kubernetes storage components work, their sequence of operations, common issues, and troubleshooting steps.
---
### Understanding the Basics: EC2 to Docker to Kubernetes

> `EC2 Storage`

- `Root Volume`: Each EC2 instance comes with a root volume (EBS by default), whose lifecycle is tied to the instance. If the instance is terminated, the root volume can also be deleted (depending on settings).

- `Attach Additional EBS`: EBS volumes can be attached to EC2 instances as separate disks. Data persists beyond the lifecycle of the instance, allowing reattachment to other instances.

- `Manual Mounting`: After attaching EBS, you manually create a mount point to use the storage in your application.

> `Docker Storage`

- Containers are ephemeral, meaning their storage is lost once the container stops.

> Solutions: How to avoid data loss on Docker

- `Volumes`: Managed by Docker itself and stored in `/var/lib/docker/volumes` on the host. Persistent but harder to manage across environments.

- `Bind Mounts`: Mount host machine directories into the container. Example:
```
volumes:
  - /host/path:/container/path
```

- If using EBS for storage, you bind-mount a directory from the EBS volume to the container. Same process applies as with the root volume.

> `Kubernetes Storage`

- Kubernetes abstracts storage management from individual nodes to the cluster level, enabling scalability and dynamic provisioning.

- Kubernetes Storage Components

  - 1. `PersistentVolume (PV)` : Represents a storage resource in the cluster, such as `EBS`, `EFS`, or local storage.

    - Created manually or dynamically provisioned using a `StorageClass`.

    - Decoupled from pods and persists beyond pod lifecycles.

    - 2. `PersistentVolumeClaim (PVC)` : A request for storage made by a `pod`.

        - PVCs bind to available PVs or trigger dynamic provisioning (if configured with a StorageClass).

        - Acts as an interface for pods to use storage resources.

    - 3. `StorageClass` Automates the creation of PVs dynamically.

        - Configured with a provisioner (e.g., `ebs.csi.aws.com`, `efs.csi.aws.com`).

    - Parameters define specific backend configurations (e.g., volume type, filesystem).

> ## How Kubernetes Fills the Storage Gaps

> `EC2 Analogy`: 
- K8s storage operates at the cluster level, not node-specific like EC2 volumes.
- Kubernetes abstracts manual storage operations such as mounting EBS.

> `Docker Analogy`:
- Instead of bind mounts, K8s uses PVCs to claim storage from the cluster.
- Unlike Docker volumes, K8s supports dynamic provisioning with StorageClass.

> Sequence of Storage Operations in Kubernetes

1. `~Manual PV Creation~` : Define a PersistentVolume:
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: ebs.csi.aws.com
    volumeHandle: vol-0abcd1234
```

2. `~Claim the PV using a PVC:~`
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

3. `~Attach PVC to a Pod:~`
```
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: example-pvc
  containers:
    - name: app-container
      image: nginx
      volumeMounts:
        - mountPath: /data
          name: storage
```
 ### Automating the creation on PV using StorageClass
4. `~Dynamic Provisioning with StorageClass~` ( No need of manual creation of PV)

- Create a StorageClass:
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
```
- Create a PVC:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ebs-sc
```
- The cluster provisions an EBS volume automatically and binds it to the PVC.

EFS vs. EBS in Kubernetes

Feature

EFS

EBS

Access Modes

ReadWriteMany (shared storage)

ReadWriteOnce (block storage)

Use Case

Shared storage between pods

Single-pod persistent storage

Dynamic Provisioning

Yes (via efs.csi.aws.com)

Yes (via ebs.csi.aws.com)

StorageClass Reuse

Typically single shared class

Often app-specific classes

Common Issues and Troubleshooting

1. PVC Stuck in Pending

Cause: No matching PV or StorageClass misconfiguration.

Solution: Check PV availability or StorageClass settings.

kubectl describe pvc <pvc-name>
kubectl get storageclass

2. EFS Mount Issues

Cause: EFS CSI driver misconfigured.

Solution: Verify EFS driver installation and IAM permissions.

kubectl get pods -n kube-system
kubectl logs <efs-driver-pod> -n kube-system

3. EBS Volume Not Attached

Cause: Node binding issues or volumeBindingMode set incorrectly.

Solution: Ensure WaitForFirstConsumer mode if using node affinity.

kubectl describe pv <pv-name>

Key Observations

Reuse StorageClass when possible to simplify management.

Choose EFS for shared storage use cases and EBS for dedicated storage needs.

Use monitoring tools (e.g., Prometheus, Grafana) to track storage metrics and health.

This guide provides an end-to-end understanding of Kubernetes storage, from the basics to advanced configurations. By applying these concepts, you can manage storage effectively in your Kubernetes clusters.

# What Are Provisioners (EBS and EFS)?

- The provisioner field in a `StorageClass` determines the CSI (Container Storage Interface) driver responsible for provisioning storage dynamically. 
- These drivers bridge Kubernetes and underlying storage systems.

> Common Provisioners for AWS:
- `AWS`
- `ebs.csi.aws.com:`
    - Manages AWS EBS volumes.
    - Block storage, ReadWriteOnce access mode.
    - Typically used for applications requiring dedicated storage.

- `efs.csi.aws.com:`
    - Manages AWS EFS volumes.
    - Network file system, ReadWriteMany access mode.
    - Suitable for shared storage between multiple pods.

# Provisioner List for Other Storage Types:

- `GCP`:
    - pd.csi.storage.gke.io (Persistent Disk)
    - filestore.csi.storage.gke.io (Filestore)
- `Azure`:
    - disk.csi.azure.com (Azure Disk)
    - file.csi.azure.com (Azure Files)
- `On-Prem or Multi-Cloud:`
    - rook-ceph.rbd.csi.ceph.com (Ceph RBD)
    - longhorn.io/longhorn (Longhorn)
    - nfs.csi.k8s.io (NFS)
    - local.csi.storage.k8s.io (Local Storage)

## Lets understad the concept with example
- In Kubernetes, the PVC and PV are matched based on specific criteria. If the PVC requests 11 GiB of storage, and the available PV is only 10 GiB, they will not bind. 
- The reasons are:

> Storage Capacity Matching:
- Kubernetes ensures that the requested capacity (resources.requests.storage) in the PVC is less than or equal to the available capacity defined in the PV's spec.capacity.storage.

> Access Modes Matching:
- The PVC's requested accessModes must match one of the accessModes defined in the PV.

> Storage Class Matching:
- If the PVC specifies a storageClassName, only PVs with the same storageClassName will be considered for binding.

> If no PV matches all these conditions, 
- the PVC will remain in the Pending state. 
- This ensures that storage resources are correctly allocated and prevents mismatches that could lead to runtime errors or application failures.

>Key Notes:

- If you're using dynamic provisioning via StorageClass, the cluster will attempt to create a new PV that satisfies the PVC's requirements. This eliminates manual matching concerns.
- For manual PV creation, always ensure that the PV's capacity, accessModes, and storageClassName align with the requirements of the PVCs that will use them.


> PersistentVolume (PV) is already bound to a PersistentVolumeClaim (PVC) and thus used by a pod, it cannot be reused by another PVC. Here’s why:
> Key Reasons:

- One-to-One Binding: A PV can only be bound to a single PVC at a time. Once the binding occurs, the PV is "claimed" and no longer available for other PVCs.

- Binding Is Permanent: After a PV is bound to a PVC, it remains bound until the PVC is deleted, and the PV's persistentVolumeReclaimPolicy determines whether the PV is released, retained, or recycled.

- Pending State: If another PVC requests the same storage capacity (e.g., 11 GiB) and no other PV meets the criteria, the new PVC will remain in the Pending state.

## WHat these each fields mean
- kubectl get pv
```
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM         STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
jenkins-pv      5Gi        RWO            Retain         Available                  manual         <unset>                          51d
pvc-a3e92d76    10Gi       RWX            Delete           Bound    ns-sonar/pvc-efs   efs          <unset>                         56d
```
kubectl get pv Columns
1. NAME

    The name of the PersistentVolume (PV). It can be assigned manually (if creating the PV statically) or automatically by Kubernetes (if dynamically provisioned).

2. CAPACITY

    Total storage capacity of the PV, e.g., 5Gi (5 GiB). It represents the maximum storage space available for a pod to use via a PVC.

3. ACCESS MODES

    Defines how the PV can be mounted by pods. Possible values:
        ReadWriteOnce (RWO):
            The volume can be mounted as read/write by a single node.
            Common for block storage like AWS EBS.
        ReadOnlyMany (ROX):
            The volume can be mounted as read-only by multiple nodes.
            Useful for shared, read-only data.
        ReadWriteMany (RWX):
            The volume can be mounted as read/write by multiple nodes.
            Common for shared file systems like AWS EFS.

4. RECLAIM POLICY

    Specifies what happens to the PV when the PVC bound to it is deleted. Possible values:
        Retain:
            The PV is not deleted and retains its data. It requires manual cleanup.
        Delete:
            The PV and the associated storage resource (e.g., an EBS volume) are deleted when the PVC is deleted.
        Recycle (Deprecated):
            The PV is scrubbed (data cleared) and made available for new claims.

5. STATUS

    Current state of the PV:
        Available: The PV is not bound to any PVC and is available for use.
        Bound: The PV is claimed by a PVC and in use.
        Released: The PVC bound to the PV is deleted, but the PV is not yet reclaimed.
        Failed: An error occurred with the PV.

6. CLAIM

    Name of the PVC bound to the PV. If empty, the PV is unclaimed and available.

7. STORAGECLASS

    The StorageClass associated with the PV, if any. It defines the provisioning rules for the PV.

8. VOLUMEATTRIBUTESCLASS

    Attributes specific to the underlying storage driver or provisioner (e.g., EBS or EFS). It can include details such as volume ID, filesystem type, or mount options.

9. REASON

    Any additional information explaining the current status or errors related to the PV.

10. AGE

    Time since the PV was created in the cluster.


kubectl get sc Columns
1. NAME

    Name of the StorageClass. This is referenced in PVCs to dynamically provision volumes.

2. PROVISIONER

    Specifies the plugin or driver used to provision volumes dynamically. Examples:
        ebs.csi.aws.com: For AWS Elastic Block Store (EBS).
        efs.csi.aws.com: For AWS Elastic File System (EFS).
        kubernetes.io/aws-ebs: Legacy AWS EBS in-tree provisioner.

3. RECLAIMPOLICY

    The default reclaim policy for PVs created by this StorageClass. Values are:
        Retain: Keeps the storage resource even after the PVC is deleted.
        Delete: Deletes the underlying storage resource when the PVC is deleted.

4. VOLUMEBINDINGMODE

    Determines when a PV is bound to a PVC. Values are:
        Immediate:
            PVs are bound to PVCs as soon as the PVC is created, regardless of pod scheduling.
            Default mode for most provisioners.
        WaitForFirstConsumer:
            PV binding is delayed until a pod using the PVC is scheduled. This ensures the PV is provisioned in the same zone as the pod.
            Common for zone-specific storage like EBS.

5. ALLOWVOLUMEEXPANSION

    Indicates whether PVCs created using this StorageClass can be resized after creation:
        true: PVCs can be expanded by updating the resources.requests.storage field.
        false: PVC resizing is not allowed.

6. AGE

    Time since the StorageClass was created.

Key Observations

    Reclaim Policy: Use Retain for manual storage management (to avoid accidental deletions) and Delete for automated cleanups.
    VolumeBindingMode:
        Use WaitForFirstConsumer for multi-zone clusters or when pods must dictate the PV's zone.
        Use Immediate for general use cases with no zone affinity requirements.
    AllowVolumeExpansion: Crucial for flexible applications that may need more storage in the future.

Example Troubleshooting Scenarios

    PVC Stuck in Pending:
        Cause: No matching PV available for the requested StorageClass, size, or access mode.
        Solution: Check StorageClass and VolumeBindingMode. Use:

        kubectl describe pvc <pvc-name>
        kubectl get pv

    PV Status is Released:
        Cause: PVC was deleted, but the PV has a Retain reclaim policy.
        Solution: Manually clean up and delete or reconfigure the PV.

    Pod Stuck in Scheduling:
        Cause: WaitForFirstConsumer mode is delaying PV provisioning.
        Solution: Ensure the pod and PVC are in the same zone or update StorageClass.
