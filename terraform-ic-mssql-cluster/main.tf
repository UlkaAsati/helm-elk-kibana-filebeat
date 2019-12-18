#-------------------------------------------------------------------------------------------------------------------------
# Terraform File Name: main.tf
# Summary: Following things are handled by the Terraform file:
# 1) Resource Name: "ibm_compute_ssh_key" 
#    Import the details of an existing SSH key as a read-only data source. 
#    This key is referenced by ibm_compute_vm_instance for passwordless ssh connection 
# 2) Resource "ibm_compute_vm_instance"
#    Creates multiple Virtual Servers in SoftLayer. These servers are used for MsSQL server creation and creation of AG
# 3) Resource Name: "null_resource"
#    Null Resource is used to configure the VS with MsSQL and SQL availability group 
#    Null Resource is Triggered only when the checksum of file changes.
#    If triggred,
#      A connection is established with the VS.
#      Copies shell scripts to the Virtual Server.
#      Executes the shells scripts in the Virtual Server (Installation of MsSQL)
#      first null Resource updates the /etc/hosts file with all the provisioned VS info (IP, hostname, FQDN)
#    Multiple Null resources are defined for creation of sql Availability group with 1 primary node and 2 secondary nodes.
#		null resources are dependent on each other with depends_on flag.
#		Second null resource is triggered once first null resource is completed and so on.
#
# Script Owner : AptData Squad
#--------------------------------------------------------------------------------------------------------------------------

provider "ibm" {
  bluemix_api_key    = "${var.ibm_cloud_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

# Register public key with IBM Cloud (Softlayer/Infrastructure SSH Keys)
resource "ibm_compute_ssh_key" "public_key" {
  label      = "${var.mssql_cluster_ssh_key["name"]}"
  notes      = "This is the key that will be used by Terraform for SSH connection to sql hosts."
  public_key = "${file("${var.mssql_cluster_ssh_key["public_key_path"]}")}"
}

locals {
  mssql_cluster_ssh_key_id = "${ibm_compute_ssh_key.public_key.id}"
}

# Create a multiple VMs on IBM Cloud for sql cluster
resource "ibm_compute_vm_instance" "sqlvm" {
  count 	     = "${length(var.mssql_cluster_hostname)}" 
  hostname 	     = "${var.mssql_cluster_hostname[count.index]}"
  domain             = "${var.mssql_cluster_domain}" 
  os_reference_code  = "${var.mssql_cluster_os_reference_code}"
  datacenter         = "${var.mssql_cluster_datacenter}"
  cores              = "${var.mssql_cluster_cores}"
  memory             = "${var.mssql_cluster_memory}"
  network_speed      = "${var.mssql_cluster_network_speed}"
  disks              = "${var.mssql_cluster_disks}"
  notes              = "This is one of multiple virtual machine SQL Server for DEV."
  user_metadata      = "{\"SQL DEV\":\"This is one of multiple virtual machine SQL Server nodes for DEV\"}"
  ssh_key_ids        = ["${local.mssql_cluster_ssh_key_id}"]
  tags               = "${var.mssql_cluster_ibm_tags}"

  depends_on = ["ibm_compute_ssh_key.public_key"]
}

resource "null_resource" "hostfile" {
count = "${var.mssql_cluster_count}"
  triggers = {
  ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host  = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }

  # manage_etc_hosts
  provisioner "file" {
    content      = "${data.template_file.hosts.*.rendered[count.index]}"
    destination = "/etc/hosts"
 }
 
   # Copies the file to remote host
  provisioner "file" {
    source      = "./config/ibm_vm2"
    destination = "/root/.ssh/ibm_vm2"
 }

  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
    "chmod 400 /root/.ssh/ibm_vm2",
    ]
   }
   
depends_on = ["ibm_compute_vm_instance.sqlvm"]
}

resource "null_resource" "configure" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_SqlServerInstallScript.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host  = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }
  

  # Copies the mssql_SqlServerInstallScript.sh file
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_SqlServerInstallScript.sh"
    destination = "/tmp/mssql_cluster_SqlServerInstallScript.sh"
 }

   
  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
	"apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_SqlServerInstallScript.sh",
    "chmod +x /tmp/mssql_cluster_SqlServerInstallScript.sh",
    "bash /tmp/mssql_cluster_SqlServerInstallScript.sh",
      ]
    }

depends_on = ["null_resource.hostfile"]
}

resource "null_resource" "configurePrimary" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_dbcertificate_primary.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }

# Copies the mssql_dbcertificate_primary.sh
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_dbcertificate_primary.sh"
    destination = "/tmp/mssql_cluster_dbcertificate_primary.sh"
 }
  
# Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
	"apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_dbcertificate_primary.sh",
    "chmod +x /tmp/mssql_cluster_dbcertificate_primary.sh",
    "cd /tmp",
    "bash /tmp/mssql_cluster_dbcertificate_primary.sh ${var.mssql_cluster_hostname[0]} ${var.mssql_cluster_hostname[1]} ${var.mssql_cluster_hostname[2]} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.configure"]
}

resource "null_resource" "configureSecondary" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_dbcertificate_secondary.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }

# Copies the mssql_dbcertificate_secondary.sh
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_dbcertificate_secondary.sh"
    destination = "/tmp/mssql_cluster_dbcertificate_secondary.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
	"apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_dbcertificate_secondary.sh",
    "chmod +x /tmp/mssql_cluster_dbcertificate_secondary.sh",
    "cd /tmp",
    "bash /tmp/mssql_cluster_dbcertificate_secondary.sh ${var.mssql_cluster_hostname[0]} ${var.mssql_cluster_hostname[1]} ${var.mssql_cluster_hostname[2]} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.configurePrimary"]
}

resource "null_resource" "CreateAG" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_createAG.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }

# Copies the mssql_createAG.sh
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_createAG.sh"
    destination = "/tmp/mssql_cluster_createAG.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
	"apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_createAG.sh",
    "chmod +x /tmp/mssql_cluster_createAG.sh",
    "cd /tmp",
    "bash /tmp/mssql_cluster_createAG.sh ${var.mssql_cluster_hostname[0]} ${var.mssql_cluster_hostname[1]} ${var.mssql_cluster_hostname[2]} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.configureSecondary"]
}

resource "null_resource" "pacemaker" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_pacemakerInstall.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host  = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }


  # Copies the mssql_SqlServerInstallScript.sh file
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_pacemakerInstall.sh"
    destination = "/tmp/mssql_cluster_pacemakerInstall.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
        "apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_pacemakerInstall.sh",
    "chmod +x /tmp/mssql_cluster_pacemakerInstall.sh",
    "bash /tmp/mssql_cluster_pacemakerInstall.sh ${var.mssql_cluster_hostname[0]} ${var.mssql_cluster_hostname[1]} ${var.mssql_cluster_hostname[2]} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.CreateAG"]
}

resource "null_resource" "AGresource" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_createAGresource.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host  = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }


  # Copies the mssql_createAGresource.sh file
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_createAGresource.sh"
    destination = "/tmp/mssql_cluster_createAGresource.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
        "apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_createAGresource.sh",
    "chmod +x /tmp/mssql_cluster_createAGresource.sh",
    "bash /tmp/mssql_cluster_createAGresource.sh ${var.mssql_cluster_hostname[0]} ${var.mssql_cluster_hostname[1]} ${var.mssql_cluster_hostname[2]} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.pacemaker"]
}


# Create a VM for influxdb 
resource "ibm_compute_vm_instance" "influxdb" {
  hostname           = "${var.mssql_cluster_influxdbhost}"
  domain             = "${var.mssql_cluster_domain}"
  os_reference_code  = "${var.mssql_cluster_os_reference_code}"
  datacenter         = "${var.mssql_cluster_datacenter}"
  cores              = "${var.mssql_cluster_cores}"
  memory             = "${var.mssql_cluster_memory}"
  network_speed      = "${var.mssql_cluster_network_speed}"
  disks              = "${var.mssql_cluster_disks}"
  notes              = "This is one of multiple virtual machine SQL Server for DEV."
  user_metadata      = "{\"SQL DEV\":\"This is one of multiple virtual machine SQL Server nodes for DEV\"}"
  ssh_key_ids       = ["${local.mssql_cluster_ssh_key_id}"]
  tags                 = "${var.mssql_cluster_ibm_tags}"

  depends_on = ["ibm_compute_ssh_key.public_key"]
}

resource "null_resource" "influxdb" {
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_setup_influxdb.sh"))}"
    ipv4_address = "${ibm_compute_vm_instance.influxdb.ipv4_address}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host = "${ibm_compute_vm_instance.influxdb.ipv4_address}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }


  # Copies the mssql_createAGresource.sh file
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_setup_influxdb.sh"
    destination = "/tmp/mssql_cluster_setup_influxdb.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
        "apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_setup_influxdb.sh",
    "chmod +x /tmp/mssql_cluster_setup_influxdb.sh",
    "bash /tmp/mssql_cluster_setup_influxdb.sh",
      ]
    }

depends_on = ["null_resource.AGresource"]
}

resource "null_resource" "collectd" {
  count = "${var.mssql_cluster_count}"
  triggers = {
    file = "${sha1(file("./shell_scripts/mssql_cluster_setup_collectd.sh"))}"
    ipv4_address_list = "${ibm_compute_vm_instance.sqlvm.*.ipv4_address[count.index]}"
  }

  # Define the SSH keys used to make connection to host
  connection {
    user = "root"
    type = "ssh"
    host = "${element(ibm_compute_vm_instance.sqlvm.*.ipv4_address, count.index + 1)}"
    private_key = "${file("${var.mssql_cluster_ssh_key["private_key_path"]}")}"
    timeout = "${var.mssql_cluster_timeout}"
  }


  # Copies the mssql_createAGresource.sh file
  provisioner "file" {
    source      = "./shell_scripts/mssql_cluster_setup_collectd.sh"
    destination = "/tmp/mssql_cluster_setup_collectd.sh"
 }


  # Execute commands on the host using the 'remote-exec' provisioner
  provisioner "remote-exec" {
    inline = [
        "apt-get update",
    "sudo apt-get install dos2unix",
    "dos2unix /tmp/mssql_cluster_setup_collectd.sh",
    "chmod +x /tmp/mssql_cluster_setup_collectd.sh",
    "bash /tmp/mssql_cluster_setup_collectd.sh ${ibm_compute_vm_instance.influxdb.ipv4_address} ${var.mssql_cluster_influx_db_port} ${var.mssql_cluster_sql_username} ${var.mssql_cluster_sql_password}",
      ]
    }

depends_on = ["null_resource.influxdb"]
}
