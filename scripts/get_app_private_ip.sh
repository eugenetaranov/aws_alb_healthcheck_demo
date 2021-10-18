#!/bin/sh

aws ec2 describe-instances --filters "Name=tag:Name,Values=test-app" --query "Reservations[*].Instances[0].PrivateIpAddress" --output json
