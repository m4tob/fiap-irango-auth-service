#!/bin/bash


init:
	terraform -chdir=terraform init -migrate-state

init-reconfigure:
	terraform -chdir=terraform init -reconfigure

plan:
	terraform -chdir=terraform plan

up:
	terraform -chdir=terraform apply -auto-approve

down:
	terraform -chdir=terraform destroy -auto-approve