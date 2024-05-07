#!/bin/bash


init:
<<<<<<< HEAD
	terraform -chdir=src init -migrate-state

init-reconfigure:
	terraform -chdir=src init -reconfigure
=======
	terraform -chdir=terraform init  -migrate-state
>>>>>>> a1e2cfb7e44dd32dfa0b67ed05e68d95e01efb18

plan:
	terraform -chdir=terraform plan

up:
	terraform -chdir=terraform apply

down:
	terraform -chdir=terraform destroy