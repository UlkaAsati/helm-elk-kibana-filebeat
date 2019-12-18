#-------------------------------------------------------------------------------------
# Terraform File Name: main_config.tfvars
# Summary: Terraform Configuration File 
#
# Script Owner : DevOps Squad
#---------------------------------------------------------------------------------------

#IBM cloud Details

ibm_cloud_api_key = "uT4jsUcLgHHuWYuwfHjl11VOUwcV32Ej8jj3gxc8hAti"

ibm_endpoint = "api.ng.bluemix.net"

ibm_sl_username = "1531383_ajha@apttus.com"

ibm_sl_api_key = "20a00d97e37b85e5b25e547f5976c88ccc0c3a3e181f2ca48b8f2fdc92ce87fd"

ibm_org_name = "Cloud Platform"

ibm_space_name = "dev"

ibm_tags = ["Development"]

#mssql-cluster details

mssql_cluster_hostname {
    "0" = "sqlnode1"
    "1" = "sqlnode2"
    "2" = "sqlnode3"
  } 

mssql_cluster_influxdbhost = "influxdb"

mssql_cluster_domain = "apttuscloud.dev"

mssql_cluster_datacenter = "dal09"

mssql_cluster_os_reference_code = "UBUNTU_16_64"

mssql_cluster_network_speed = "1000"

mssql_cluster_cores = "4"

mssql_cluster_memory = "8192"

mssql_cluster_disks = [100]

mssql_cluster_ssh_key = {
  name             = "terraform_ssh_key"
  public_key_path  = "./config/ibm_vm2.pub"
  private_key_path = "./config/ibm_vm2"
}

mssql_cluster_ibm_tags = ["Development"]

mssql_cluster_count = "3"

mssql_cluster_timeout = "50s"

mssql_cluster_influx_db_port = "25826"
                                   
mssql_cluster_sql_username = "SA"

mssql_cluster_sql_password = "@pttusPassword*ReplaceM3!"

mssql_cluster_vlan_public_id = "2417689"

mssql_cluster_vlan_private_id = "2417691"

