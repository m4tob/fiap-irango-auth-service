#!/bin/bash

init:
	terraform -chdir=src init  -migrate-state

plan:
	terraform -chdir=src plan

up:
	terraform -chdir=src apply

down:
	terraform -chdir=src destroy