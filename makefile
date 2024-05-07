#!/bin/bash

init:
	terraform -chdir=terraform init  -migrate-state

plan:
	terraform -chdir=terraform plan

up:
	terraform -chdir=terraform apply

down:
	terraform -chdir=terraform destroy