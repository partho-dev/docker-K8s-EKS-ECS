1. Enter the private nexus info on the 01.dockerconnfig.json file
2. then encode that content in base64
- `cat dockerconfig.json | base64`
3. copy the output of 2
4. open 02.nexus_secret.yaml file and update the output on `.dockerconfigjson`
5. Make sure it remains on the same line of `.dockerconfigjson`


## Note:
- This secret needs to be updated to all `ns` of the target eks where application has to be deployed

6. For the same nexus, the entire secret will remain same, only need to change the `ns`

7. On the application deployment(on the github) make sure the `spec.imagePullSecrets.name` should be `nexuscreds` or any name that is mentioned on the `secret.metadata.name`