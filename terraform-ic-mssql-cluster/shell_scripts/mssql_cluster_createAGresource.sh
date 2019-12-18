#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_createAGresource.sh
# Summary: Following things are handled by the Shell script :
# Saves the creentials for sqlServer login and Creates availability group resource and checks the pcs status
#
# Script Owner : AptData Squad
#---------------------------------------------------------------------------------------------------------------

#!/bin/bash

set -e

SQL_NODE1=$1
SQL_NODE2=$2
SQL_NODE3=$3
SQL_USERNAME=$4
SQL_PASSWORD=$5


#On all SQL Servers, save the credentials for the SQL Server login.
echo 'pacemakerLogin' >> ~/pacemaker-passwd
echo $SQL_PASSWORD >> ~/pacemaker-passwd
sudo mv ~/pacemaker-passwd /var/opt/mssql/secrets/passwd
sudo chown root:root /var/opt/mssql/secrets/passwd
sudo chmod 400 /var/opt/mssql/secrets/passwd # Only readable by root

sleep 8

if [ $? -eq 0 ]; then
        if [ "$HOSTNAME" = $SQL_NODE1 ]; then
                sudo pcs resource create ag_cluster ocf:mssql:ag ag_name=ag1 meta failure-timeout=30s --master meta notify=true

                sudo pcs cluster enable --all
                sudo pcs property set stonith-enabled=false
        fi
fi

sleep 5

if [ $? -eq 0 ]; then
	sleep 3
        sudo pcs status
fi
