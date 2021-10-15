##### Setup
1. Generate ssh key
```shell
cd tf
ssh-keygen -t rsa
```

2. Apply terraform
```shell
terraform init
terraform apply
```

##### Test
1. Connect to the app node
```shell
cd tf
ssh-add id_rsa
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J ubuntu@$(terraform output -raw gw_ip) ubuntu@$(terraform output -raw app_private_ip)
```

2. Confirm web node passed healthcheck in AWS console.
3. Update app timeouts on the app node, ELB healthchecks will start failing:
```shell
sudo -i
cd /opt/app
echo 7 > elb_healthcheck_delay.txt ; echo 25 > default_delay.txt
```
4. Run check locally:
```shell
cd tf
curl -w %{time_total} $(terraform output -raw app_url) ; echo
```

##### Cleanup
```shell
cd tf
terraform destroy
```
