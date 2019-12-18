data "template_file" "hosts" {
  template = "${file("./templates/etc_host_entry.tpl")}"
  count =  "${length(var.mssql_cluster_hostname)}"
  vars {
    ipv4_address_1 = "${ibm_compute_vm_instance.sqlvm.0.ipv4_address}"
     ipv4_address_2 = "${ibm_compute_vm_instance.sqlvm.1.ipv4_address}" 
     ipv4_address_3 = "${ibm_compute_vm_instance.sqlvm.2.ipv4_address}"    
     host_1 =  "${var.mssql_cluster_hostname[0]}"
     host_2 =  "${var.mssql_cluster_hostname[1]}"
     host_3 =  "${var.mssql_cluster_hostname[2]}"
    domain = "${var.mssql_cluster_domain}" 

  }
}
