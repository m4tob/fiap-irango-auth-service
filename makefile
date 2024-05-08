#!/bin/bash

init:
	terraform -chdir=terraform init  -migrate-state

plan:
	terraform -chdir=terraform plan

up:
	terraform -chdir=terraform apply -auto-approve

down:
	terraform -chdir=terraform destroy -auto-approve