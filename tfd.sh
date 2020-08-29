#!/bin/bash

export TF_LOG=TRACE
export TF_LOG_PATH="/tmp/terraform-destroy-$(date "+%Y-%m-%d_%H:%M").log"
terraform destroy --auto-approve
ls -ltr /tmp/terraform-destroy*.log | tail -n 1
