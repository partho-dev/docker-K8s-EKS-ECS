## Why do we need EKSCTL

- It is a tool that is specifically used to create EKS cluster on AWS
- As per the AWS documentation, there are 3 ways, we can create EKS cluster on AWS `https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html`
    - through EKSCTL
    - through AWS CLI
    - Through AWS management console
    - Through IaC like Terraform (Optional)

### EKSCTL is a tool, that needs to be installed on the source system (DevOps engineer laptop or Jenkins Server)

### Installation of EKSCTL on MAC  
- Make sure homebrew package installar is installed on mac already, if not
- install brew through this
- `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

- Connect to the repo of brew using this for eksctl
- `brew tap weaveworks/tap`

- execute `eksctl` installation with the command- `brew install weaveworks/tap/eksctl`

- Check version - `eksctl version`


## How the EKSCTL knows which AWS account it has to create the cluster

### EKSCTL command can be run from `local laptop` (laptop is eksctl client & aws is the destination)

- In the case of local laptop
- eksctl looks for the aws config & aws credentials file (` ~/.aws/credentials`)
- based on that, it decides the aws destination
- If there are many profiles in aws credentials

- `~/.aws/credentials`
    ```
    [default]
    aws_access_key_id = <YOUR_ACCESS_KEY>
    aws_secret_access_key = <YOUR_SECRET_KEY>
    ```

- If there are more than one profile, we can explocitly use the profile name during deployment
- `eksctl create cluster --profile your-profile-name`

### EKSCTL command can be run from `jenkins server` on Ec2 (Jenkins server is eksctl client & aws is the destination)
- We will create a role & attach that role to the Jenkins server
- Then if we run eksctl, it automatically detects the target aws

