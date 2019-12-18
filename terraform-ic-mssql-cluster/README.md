# Terraform-IBM-MSSQL-AG

<!-- TOC -->

- [Terraform-IBM-MSSQL](#terraform-ibm-mssql)
    - [Description](#description)
    - [Prerequisites](#prerequisites)
        - [Install Terraform](#install-terraform)
        - [Install Terraform IBM Provider](#install-terraform-ibm-provider)
    - [Folder Structure](#folder-structure)
    - [Terraform Configuration](#terraform-configuration)
        - [Configure IBM Credentials](#configure-ibm-credentials)
        - [Configure AWS Backend](#configure-aws-backend)
    - [Usage](#usage)
        - [Terraform Workspace](#terraform-workspace)
        - [Terraform Init](#terraform-init)
        - [Terraform Plan](#terraform-plan)
        - [Terraform apply](#terraform-apply)
    - [Outputs](#outputs)
    - [Testing](#testing)
        - [How to Store Terraform State file locally](#how-to-store-terraform-state-file-locally)
        - [How to Run MS SQL Terraform Project](#how-to-run-MSSQL-terraform-project)
    - [Configuration](#configuration)
        - [Makefile Properties](#makefile-properties)
        - [Jenkinsfile Properties](#jenkinsfile-properties)
    - [Makefile](#makefile)
        - [Makefile Description](#makefile-description)
        - [Prerequisties for Local Run](#prerequisties-for-local-run)
            - [Install Make](#install-make)
        - [Check if Variables are defined](#check-if-variables-are-defined)
        - [Module Package](#module-package)
        - [Module Check](#module-check)
        - [Module Push](#module-push)
        - [Clean](#clean)
        - [All](#all)
    - [Jenkinsfile](#jenkinsfile)
    - [References](#references)

<!-- /TOC -->

## Description

Responsibilty of this TF MsSQL Cluster TF project is to create following things:
- Imports Public SSH Key present in IBM SoftLayer
- Provisions a 3 Virtual Servers (1 primary node and 2 secondary nodes)
- Configures MsSQL
- Configure SQL Server Always On Availability Group for high availability on Linux
- Configure cluster resource manager, Pacemaker
- Provisions VM and installs influxdb for monitoring
- Installs collectd on sql nodes for monitoring


## Prerequisites

### Install Terraform

Follow below link to install Terraform

- [Terraform Install](https://www.terraform.io/intro/getting-started/install.html)

### Install Terraform IBM Provider

- [IBM Provider Install](https://ibm-cloud.github.io/tf-ibm-docs/)

## Folder Structure

```bash
│   .gitignore
│   config.properties
│   Makefile
│   Jenkinsfile
│   config.tfvars
│   main.tf
│   outputs.tf
│   README.md
│   variables.tf
│   templates.tf
│
├───config
│       acl
│       acl.pub
│       ibm_vm2
│       ibm_vm2.pub
│
├───shell_scripts
│       mssql_SqlServerInstallScript.sh
│       mssql_createAG.sh
│       mssql_dbcertificate_primary.sh
│       mssql_dbcertificate_secondary.sh
│		mssql_pacemakerInstall.sh
│		mssql_createAGresource.sh
│		mssql_cluster_setup_influxdb.sh
│		mssql_cluster_setup_collectd.sh
│
├───templates
│       etc_host_entry.tpl

```

## Terraform Configuration

### Configure IBM Credentials

Configure following values in config.tfvars file

```bash
# IBM Cloud Platform Key
ibmcloud_api_key = ""

# IBM SoftLayer Username
ibm_sl_username = ""

# IBM SoftLayer API Key
ibm_sl_api_key = ""

# IBM Tags 
ibm_tags = ["Development"]
```
## Input Variables

### ibm_compute_ssh_key
Parameter | Description | Default
--- | --- | ---
ibm_vm2 | SSH Key Name | **required**

### ibm_compute_vm_instance
Parameter | Description | Default
--- | --- | ---
`mssql_cluster_count` | to scale up VMs | **required**
`mssql_cluster_hostname` | Virtual Server Hostname | **required**
`mssql_cluster_domain` | Virtual Server Domain Name| **required**
`mssql_cluster_os_reference_code` | Virtual Server OS Reference Code | **required**
`mssql_cluster_datacenter` | Virtual Server Datacenter Location| **required**
`mssql_cluster_cores`| Virtual Server Numnber of Cores| **required**
`mssql_cluster_memory` | RAM size of Virtual Server| **required**
`mssql_cluster_network_speed` | Network Speed| **required**
`mssql_cluster_disks` | Number of external disks attachecd to the VS | **required**
`mssql_cluster_notes` | Virtual Server Notes | **required**
`mssql_cluster_timeout` | The timeout to wait for the connection to become available | **required**
`mssql_cluster_ssh_key ` | SSH key Details | **required**
`mssql_cluster_influxdbhost` | The hostname for the computing instance | **required**
`mssql_cluster_influx_db_port` | port to connect to influx db | **required**
`mssql_cluster_sql_username` | sql username to connect to sql server | **required**
`mssql_cluster_sql_password` | sql password to connect to sql server | **required**
`mssql_cluster_vlan_public_id` | The public VLAN ID for the public network interface of the instance | **required**
`mssql_cluster_vlan_private_id` | The private VLAN ID for the private network interface of the instance | **required**

### null_resource
Parameter | Description | Default
--- | --- | ---
`public_key_path` | SSH priavte key Path | **required**
`host` | Address of the resource to connect to | **required**

## Output Variables

Parameter | Description

`mssql_cluster_ip` | List of MsSQL Virtual Server IP Addresses
`mssql_cluster_id` | List of MsSQL Virtual Server ids
`mssql_cluster_hostname` | List of hostnames of the sql VM instances
`mssql_cluster_influxdbhost` | influxdb Server hostname
`mssql_cluster_influxdb_IP` | influxdb Server IP

### Configure AWS Backend

Export AWS Credentials

```bash
export AWS_ACCESS_KEY_ID=""

export AWS_SECRET_ACCESS_KEY=""
```

## Usage

There are three stages in Terraform Deployment.

### Terraform Workspace

Terraform will create workspace for running the terraform commands in different environments.

```bash
terraform workspace new development

terraform workspace list
```

### Terraform Init

Terraform initialize following things during Terraform init:

- Initialize the modules
- Initialize the Terraform Backend to remotely store the Terraform State file
- Initialize the Plugins

```bash
terraform init  -var-file config.tfvars
```

### Terraform Plan

Terraform Plan will all the resources created or updated by terraform plan.

```bash
terraform plan  -var-file config.tfvars
```

### Terraform apply

Terraform apply the Kubernetes cluster module to create Kubernetes cluster.

Terraform apply all to create all the rest of the infra in IBM cloud environment

```bash
terraform apply  -var-file config.tfvars
```

## Output Variables
Parameter | Description | Default
--- | --- | ---
`ip` | List of MsSQL Virtual Server IP Addresses | **required**
`id` | List of MsSQL Virtual Server ids | **required**

## Testing

### How to Store Terraform State file locally

Comment the code in backend.tf file. This will ensure the Terraform state is stored locally.

### How to Run this Terraform project.

```bash
terraform init  -var-file config.tfvars

terraform plan  -var-file config.tfvars

terraform apply  -var-file config.tfvars
```

## Configuration

config.properties file is used to store all the properties required for Jenkinsfile and Makefile.

### Makefile Properties

Parameter | Description | Default
--- | --- | ---
`MOD_NAME_PREFIX` | Module Name Prefix  | **required**
`MOD_VERSION` | Module Version | **required**
`MOD_AWS_BUCKET_NAME` | Module Registry AWS bucket Name | **required**
`MOD_PACKAGE_EXT` | Module zip file type | **required**

### Jenkinsfile Properties

Parameter | Description | Default
--- | --- | ---
`JENKINS_SLACK_CHANNEL` | Slack Channel for email notifications | **required**
`JENKINS_AWS_CREDS_ID` | AWS Credentials ID in Jenkins | **required**

## Makefile

### Makefile Description

This Makefile does following things:

- Creates Zip file which includes all the files.
- Checks if the Zip file is present the AWS S3 registry.
- If the File is not present it uploads the file to S3 Module Registry.
- Removes the zip file from local environment.

### Prerequisties for Local Run

Install following softwares in local UBUNTU:16.04 machine

#### Install Make

```bash
apt-get update
apt-get install -y make
```

### Check if Variables are defined

Check  if variables are defined for AWS

```bash
make check-aws-defined AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY=""
```

Check if variables are defined for Module name

```bash
make check-mod-defined
```

### Module Package

Zip the all the files in the repository

```bash
make package
```

### Module Check

Check if the Module is already present in the AWS S3 module registry.

```bash
make push  AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY=""
```

### Module Push

Push the Module to the AWS registry.

```bash
make push  AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY=""
```

### Clean

Remove the Zipped file from the local.

```bash
make clean
```

### All

All will run all the targets in sequence
Sequence: check-aws-defined --> check-mod-defined -->  package --> check --> push --> clean

```bash
export AWS_ACCESS_KEY_ID = ""
export AWS_SECRET_ACCESS_KEY = ""
make all
```

## Jenkinsfile

**Module Package:** Compress all the file in repository to a Zip file.

**Module Push:** Check if the Module is available in AWS S3 Registry, else upload it.

**Clean Up:** Remove the zip file from the local.

## References

- [Terraform Backend](https://www.terraform.io/docs/backends/types/s3.html)
- [Terraform IBM Provider](https://ibm-cloud.github.io/tf-ibm-docs/)
- [Terraform Modules](https://www.terraform.io/docs/modules/index.html)
