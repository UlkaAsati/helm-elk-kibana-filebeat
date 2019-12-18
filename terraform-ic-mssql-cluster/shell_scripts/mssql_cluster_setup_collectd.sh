#!/bin/bash

#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_cluster_setup_influxdb.sh
# Summary: Following things are handled by the Shell script :
# Installation of collectd on sql nodes
#
# Script Owner : AptData Squad
#---------------------------------------------------------------------------------------------------------------


set -eo pipefail

if [ $# -ne 4 ]; then
    printf "\r\nUsage:- ./setup-collectd.sh '<INFLUX_DB_SERVER IP>' '<INFLUX_DB_PORT>' '<SQL_USERNAME>' '<SQL_PASSWORD>'\r\n"
	printf "\r\nExiting...\r\n"
	exit
fi

printf "\r\nSetting up collectd on the Linux SQL Server you want to monitor\r\n"

INFLUX_DB_SERVER=$1
INFLUX_DB_PORT=$2
SQL_USERNAME=$3
SQL_PASSWORD=$4
SQL_HOSTNAME=`hostname`

#Step 1. Using SSMS or SQLCMD, create a SQL account to be used with collectd.
printf "\r\nStep 1. Using SSMS or SQLCMD, create a SQL account to be used with collectd.\r\n"
cat <<EOT >> sqlcmdinput.sql
USE master;
GO
CREATE LOGIN [collectd] WITH PASSWORD = N'$SQL_PASSWORD';
GO
GRANT VIEW SERVER STATE TO [collectd];
GO
GRANT VIEW ANY DEFINITION TO [collectd];
GO
EOT
sqlcmd -S localhost -U SA -P $SQL_PASSWORD -i sqlcmdinput.sql

#Step 2. Install Docker Engine (if not already installed)
printf "\r\nStep 2. Install Docker Engine (if not already installed)\r\n"
{
	set +e
	docker --version | grep "Docker version"
}
if [ $? -eq 0 ]
then
	printf "\r\nDocker Engine is already installed\r\n"
else
	printf "\r\nDocker Engine is not present. Installing Docker Engine.\r\n"
	wget -qO- https://get.docker.com/ | sudo sh	
fi

#Step 3. Install Git for your distro (if not already installed)
printf "\r\nStep 3. Install Git for your distro (if not already installed)\r\n"
{
	set +e
	which git
}
if [ $? -eq 0 ]
then
	printf "\r\nGit is already installed\r\n"
else
	printf "\r\nGit is not present. Installing Git.\r\n"
	apt-get install git -y
fi

#Step 4. Clone the mssql-monitoring GitHub repository
printf "\r\nStep 4. Clone the mssql-monitoring GitHub repository\r\n"
git clone https://github.com/Microsoft/mssql-monitoring.git

#Step 5. Browse to mssql-monitoring/collectd
printf "\r\nStep 5. Browse to mssql-monitoring/collectd\r\n"
cd mssql-monitoring/collectd

#Step 6. Edit run.sh and change the variables to match your environment
printf "\r\nStep 6. Edit run.sh and change the variables to match your environment\r\n"
#The ip address of the InfluxDB server collecting collectd metrics
#INFLUX_DB_SERVER="localhost"
 
#The port that your InfluxDB is listening for collectd traffic
#INFLUX_DB_PORT="25826"
 
#The host name of the server you are monitoring. This is the value that shows up under hosts on the Grafana dashboard
#SQL_HOSTNAME="MyHostName"
 
#The username you created from step 1
#SQL_USERNAME="sqluser"
 
#The password you created from step 1
#SQL_PASSWORD="strongsqlpassword"

sed -i "s/INFLUX_DB_SERVER=\"localhost\"/INFLUX_DB_SERVER=\"$INFLUX_DB_SERVER\"/g" run.sh
sed -i "s/INFLUX_DB_PORT=\"25826\"/INFLUX_DB_PORT=\"$INFLUX_DB_PORT\"/g" run.sh
sed -i "s/SQL_USERNAME=\"sqluser\"/SQL_USERNAME=\"$SQL_USERNAME\"/g" run.sh
sed -i "s/SQL_PASSWORD=\"strongsqlpassword\"/SQL_PASSWORD=\"$SQL_PASSWORD\"/g" run.sh

sed -i "s/SQL_HOSTNAME=\"MyHostName\"/SQL_HOSTNAME=\"$SQL_HOSTNAME\"/g" run.sh


#Step 7. Execute run.sh. This will pull down the mssql-monitoring-collectd image, set it to start on reboot and create and run the container
printf "\r\nStep 7. Execute run.sh. This will pull down the mssql-monitoring-collectd image, set it to start on reboot and create and run the container\r\n"
chmod +x run.sh
./run.sh
