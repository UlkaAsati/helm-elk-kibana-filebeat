#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_pacemakerInstall.sh
# Summary: Following things are handled by the Shell script :
# Opens the required firewall ports, installs and enables pacemaker. 
# Also installs SQL Server resource agent for integration with Pacemaker
#
# Script Owner : AptData Squad
#------------------------------------------------------------------------------------------------------------

#!/bin/bash

set -e

SQL_NODE1=$1
SQL_NODE2=$2
SQL_NODE3=$3
SQL_USERNAME=$4
SQL_PASSWORD=$5

# Open the needed firewall  ports

sudo ufw allow 2224/tcp
sudo ufw allow 3121/tcp
sudo ufw allow 21064/tcp
sudo ufw allow 5405/udp
sudo ufw allow 1433/tcp # Replace with TDS endpoint
sudo ufw allow 5022/tcp # Replace with DATA_MIRRORING endpoint
sudo ufw reload

#Install Pacemaker on all nodes

sudo apt-get install pacemaker pcs fence-agents resource-agents -y

sudo echo -e "$SQL_PASSWORD\n$SQL_PASSWORD" | passwd hacluster

systemctl enable pcsd
systemctl start pcsd
systemctl enable pacemaker

pcs cluster destroy 
 
systemctl enable pacemaker

if [ "$HOSTNAME" = $SQL_NODE1 ]; then

sudo pcs cluster auth $SQL_NODE1 $SQL_NODE2 $SQL_NODE3 -u hacluster -p @pttusPassword*ReplaceM3!
sudo pcs cluster setup --name mssql-cluster  $SQL_NODE1 $SQL_NODE2 $SQL_NODE3 -force
sudo pcs cluster start --all
sudo pcs cluster enable --all
#sudo pcs property set stonith-enabled=false
fi

#Install SQL Server resource agent for integration with Pacemaker

apt-get install mssql-server-ha -y

#Create a SQL Server login for Pacemaker

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "USE [master]"
sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "CREATE LOGIN [pacemakerLogin] with PASSWORD= N'$SQL_PASSWORD'"
sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [pacemakerLogin]"
sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"


sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GRANT ALTER, CONTROL, VIEW DEFINITION ON AVAILABILITY GROUP::ag1 TO pacemakerLogin"
sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GRANT VIEW SERVER STATE TO pacemakerLogin"
sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"
