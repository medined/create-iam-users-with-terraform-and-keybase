#!/bin/bash

# Make sure the user files are up to date.
./user-add.sh

export TF_LOG=TRACE
export TF_LOG_PATH="/tmp/terraform-apply-$(date "+%Y-%m-%d_%H:%M").log"
terraform apply --auto-approve
ls -ltr /tmp/terraform-apply*.log | tail -n 1
