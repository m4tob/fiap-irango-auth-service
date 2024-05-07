#!/bin/bash


init:
	terraform -chdir=src init -migrate-state

init-reconfigure:
	terraform -chdir=src init -reconfigure

plan:
	terraform -chdir=src plan

up:
	terraform -chdir=src apply

down:
	terraform -chdir=src destroy