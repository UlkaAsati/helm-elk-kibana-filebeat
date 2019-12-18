#-------------------------------------------------------------------------------------
# Terraform File Name: variables.tf
# Summary: Following things are handled by the Terraform file:
# 1) Variable declaration  and default value initialization
# 2) There are two types of variables: String, List
#
# Script Owner : AptData Squad
#---------------------------------------------------------------------------------------
#Porvider Variables
variable "ibm_cloud_api_key" {
  description = "IBM Cloud API key"
  default     = ""
}

variable ibm_sl_username {
  description = "IBM SoftLayer Username"
  default     = ""
}

variable ibm_sl_api_key {
  description = "IBM SoftLayer API Key"
  default     = ""
}

variable "ibm_tags" {
  description = "Environment Tags"
  type        = "list"
}

# mssql_clusrer variables

variable "mssql_cluster_os_reference_code" {
   description = "The OS to be provisioned"
 }

 variable "mssql_cluster_datacenter" {
   description = "The datacenter"
 }

 variable "mssql_cluster_domain" {
   description = "The domain for the computing instance"
  }

variable "mssql_cluster_hostname" {
   description = "The hostname for the computing instance"
    type = "map"
 }

variable "mssql_cluster_cores" {
   description = "The number of CPU cores that you want to allocate."
 }


variable "mssql_cluster_memory" {
   description = "The amount of memory, expressed in megabytes, that you want to allocate."
 }


variable "mssql_cluster_network_speed" {
   description = "The connection speed (in Mbps) for the instance.s network components."
 }

variable "mssql_cluster_disks" {
   type = "list"
   description = "The numeric disk sizes (in GBs) for the instance.s block device and disk image settings."
 }

variable "mssql_cluster_count" {
   description = "paramter to scale the resources"
 }
 
variable "mssql_cluster_timeout" {
   description = "The timeout to wait for the connection to become available."
 }
 
# Specify name of local SSH key files to use
variable "mssql_cluster_ssh_key" {
  description = "SSH key Details"
  type        = "map"
}

variable "mssql_cluster_ibm_tags" {
  description = "Tags"
  type        = "list"
}

variable "mssql_cluster_influxdbhost" {
  description = "The hostname for the computing instance"
}

variable "mssql_cluster_influx_db_port" {
   description = "port to connect to influx db"
 }

variable "mssql_cluster_sql_username" {
   description = "sql username"
 }

variable "mssql_cluster_sql_password" {
   description = "sql password"
 }

variable "mssql_cluster_vlan_public_id" {
   description = "The public VLAN ID for the public network interface of the instance"
}

variable "mssql_cluster_vlan_private_id" {
   description = "The private VLAN ID for the private network interface of the instance."
}


