# Fiap iRango K8s
![terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![aws](https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)


## Dependencies
- [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)
- Make
  - [Windows](https://gnuwin32.sourceforge.net/packages/make.htm)
  - Linux:
  ```bash
  sudo apt update
  sudo apt install make
  ```

## Instructions to run
Before all, you need set AWS credentials ENVs using:
```bash
export AWS_ACCESS_KEY_ID=xxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxx
```
Or configure it in windows environments.

### Using make
```bash
# To init terraform
make init

# To run terraform plan
make plan

# To apply changes
make up
```

To destroy resources:
```bash
make down
```


### Without make
```bash
# To init terraform
terraform -chdir=src init

# To run terraform plan
terraform -chdir=src plan

# To apply changes
terraform -chdir=src apply
```

To destroy resources:
```bash
terraform -chdir=src destroy
```

