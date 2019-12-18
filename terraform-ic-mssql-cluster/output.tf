#-------------------------------------------------------------------------------------
# Terraform File Name: outputs.tf
# Summary: Following things are handled by the Terraform file:
# 1) Intialization of Output Variables which are visible after Resource creation
#  
# Script Owner : AptData Squad
#---------------------------------------------------------------------------------------

output "mssql_cluster_id" {
description = "List of ids of the VM instances."
  value = "${ibm_compute_vm_instance.sqlvm.*.id}"
}

output "mssql_cluster_ip" {
description = "List of IPv4 address of the VM instances."
 value = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address}"
}

output "mssql_cluster_hostname" {
description = "List of hostnames of the sql VM instances."
 value = "${ibm_compute_vm_instance.sqlvm.*.hostname}"
}

output "mssql_cluster_influxdbhost" {
description = "List of hostnames of the sql VM instances."
 value = "${ibm_compute_vm_instance.influxdb.hostname}"
}

output "mssql_cluster_influxdb_ip" {
description = "IPv4 address of the VM instances."
 value = "${ibm_compute_vm_instance.influxdb.ipv4_address}"
}


