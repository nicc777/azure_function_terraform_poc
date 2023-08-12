# Deploying Azure Functions using Terraform

> **note**
> This project was cloned from https://github.com/godatadriven/azure_function_terraform after I read [an article](https://godatadriven.com/blog/deploying-an-azure-function-with-terraform/) by [Niels Zeilemaker](https://github.com/NielsZeilemaker). I wanted to experiment myself, and hence cloned the original repository with the idea to adapt it to my own needs.

> **warning**
> This is NOT production code. I use it for educational purposes to explore features in MS Azure. Use at your own risk.

# Lab Description

This is a simple Azure functions application where one Python function is triggered by a timer event which in turn generates a message to send to a listener function via an event hub:

![Infrastructure](infrastructure.png)

# Testing

You will need an active Azure subscription and appropriate permissions.

Basic steps:

```shell
# Insure you are logged in - below is optional depending on your specific setup
az login

# Init terraform 
terraform init

# Check for potential errors. In te future with updates to Azure, there may be a couple of adjustments needed. Please open PR's if that is the case for you.
terraform plan

# Deploy
terraform apply
```

## Common command to try out

Get the configuration of the function application:

```shell
az functionapp config show --resource-group nico-sandbox-001 --name fa-nico-timeeventtest
```

List the functions in an application:

```shell
az functionapp function list --resource-group nico-sandbox-001 --name fa-nico-timeeventtest
```

Same as listing, but use [jq](https://jqlang.github.io/jq/) to extract the ID's:

```shell
az functionapp function list --resource-group nico-sandbox-001 --name fa-nico-timeeventtest | jq -r ".[].id"
```

