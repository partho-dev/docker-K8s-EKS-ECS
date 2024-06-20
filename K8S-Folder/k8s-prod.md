- Kubernetes has its own distributions.
    * Kubernnetes (Open source)
Then managed services by different vendors, with some additional service wrapped around the Kubernetes.
    * Openshift by RedHat
    * Rancher 
    * Tanzo by Vmware
    * AWS EKS
    * Azure AKS
    * Google GKE
    * Docker DKE

Configure K8S cluster using `KOPS (Kubernetes - Operations)` and kubernetes.
- To install the Kubernetes, we can do that inhouse or
- Install own Kubernetes cluster on Cloud like AWS

### Resources needed to create K8S cluster on AWS 
1. Need a tool called `KOPS`
2. To run that tool, we need one `EC2` server
3. A domain for the K8S cluster 

### Steps and process
1. Launnch an Ec2 instance (Ubuntu), t2.small is fine
    - ssh to that Ec2
2. Install `KOPS` on that.

    ```
    curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64

    chmod +x kops

    sudo mv kops /usr/local/bin/kops

    ```
3. Update the system `sudo apt update -y`
4. Install aws cli tool  `sudo apt install awscli -y`
5. validate if CLI is installed  `aws --version`
6. On the same Ec2 server, run `aws configure`
    - get the access key & secret access key for the admin user
    - Right click on AWS profile and click on `security credentials`
    <img width="367" alt="aws-sec-creds" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/f480e9a5-2fb5-4a94-909a-7822d1419f86">

    -  Or if its against the org policy to use admin accesskey, then create a user
    <img width="1044" alt="aws-create-user" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/03d847f6-8fd9-44cc-a9fc-97b217547157">
    - give the necessary permissions to the user
            - AmazonEC2FullAccess
            - AmazonS3FullAccess
            - IAMFullAccess
            - AmazonVPCFullAccess
    - Then get the accesskey and secret access key for that user
    - <img width="1030" alt="aws-create-programatic-key" src="https://github.com/partho-dev/docker-K8s-EKS-ECS/assets/150241170/26e62563-9217-48a6-ac3a-0985adb2e54f">
    
    * I am using the admin creds here
    
    