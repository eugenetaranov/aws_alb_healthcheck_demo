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
1. Obtain app nodes private ip addresses
```shell
sh ../scripts/get_app_private_ip.sh
```
2. Connect to the gateway node
```shell
cd tf
ssh-add id_rsa
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ForwardAgent=yes ubuntu@$(terraform output -raw gw_ip)
# start tmux
# ssh to the nodes from #1
```
3. Confirm web node passed healthcheck in AWS console.
4. Obtain a cookie to make sure subsequent request will hit the same node.
```shell
cd tf
curl -b cookie.txt -c cookie.txt -w %{time_total} $(terraform output -raw app_url) ; echo
```
4. Update app timeouts on the app node (same node that responded in previous step), ELB healthchecks will start failing:
```shell
sudo -i
cd /opt/app
echo 7 > elb_healthcheck_delay.txt ; echo 25 > default_delay.txt
```
5. Run check locally:
```shell
cd tf
curl -b cookie.txt -c cookie.txt -w %{time_total} $(terraform output -raw app_url) ; echo
```

##### Cleanup
```shell
cd tf
terraform destroy
```
