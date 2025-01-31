> Why do we need persistent volume

- DB or other applications like Jenkins need to store their configuration data and for that they need long live volume
- when we do a deploymennt, the applications store their data on the pod which may die any time and so all data would be lost.
- to retain the data even tjough the pod dies, we need to create a seperate volume(persistant volume) and assign that volume to the application (persistant volume claim)
- By default the EKS provides GP2 storage class which allows ReadWriteOnce and that allows mounting EBS Volume to a single pod.
- EKS needs to request AWS to provide volumes
- For that AWS needs a driver installed on EKS (CSI driver) - container Storage Interface
- This allocates EBS storage to EKS which provides ReadWrteOnce to the volume


## How to allocate volume size on EKS EBS
- create an EKS object "`kind: PersistentVolume`" yaml file and apply that to the EKS

- sample PV yaml file
```
# Create PV on the node 
apiVersion: v1
kind: PersistentVolume
metadata:
   name: jenkins-pv
   # namespace: devops-tools
 spec:
   capacity:
     storage: 10Gi
   accessModes:
     - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   storageClassName: manual
   hostPath:
     path: /mnt/data/jenkins  # This will store data on the worker node's disk
```

## How to assign that volume to the application (Using PVC)
- sample pvc object file
```
apiVersion: v1
kind: PersistentVolumeClaim
 metadata:
   name: jenkins-pvc
   # namespace: devops-tools
 spec:
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 10Gi

```


> ## How to make these works and complete setup of EKS CSI Driver
---

1. We would need to create a Role on AWS which should be assumed by the CSI driver on EKS
2. Assign policy to the Role for the csi driver to get permission

- To know the version of CSI drivers
```
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver
```

## TF script to set up the CSI driver on EKS and allowing to request for EBS volume for PV

```
data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${aws_eks_cluster.eks.name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Optional: only if you want to encrypt the EBS drives
resource "aws_iam_policy" "ebs_csi_driver_encryption" {
  name = "${aws_eks_cluster.eks.name}-ebs-csi-driver-encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# Optional: only if you want to encrypt the EBS drives
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
  policy_arn = aws_iam_policy.ebs_csi_driver_encryption.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# add the role arn to service account, so the CS Idriver can assume it
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}

# Install CSI Driver to EKS
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.31.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [aws_eks_node_group.general]
}
```