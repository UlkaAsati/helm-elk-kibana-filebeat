#!/bin/bash

#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_cluster_setup_influxdb.sh
# Summary: Following things are handled by the Shell script :
# Installation of InfluxDB on VM
#
# Script Owner : AptData Squad
#------------------------------------------------------------------------------------------------------------

set -eo pipefail

printf "\r\nSetting up InfluxDB\r\n"

#Step 1. Install Docker Engine (if not already installed)
printf "\r\nStep 1. Install Docker Engine (if not already installed)\r\n"
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

#Step 2. Install Git for your distro (if not already installed)
printf "\r\nStep 2. Install Git for your distro (if not already installed)\r\n"
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

#Step 3. Clone the mssql-monitoring GitHub repository
printf "\r\nStep 3. Clone the mssql-monitoring GitHub repository\r\n"
git clone https://github.com/Microsoft/mssql-monitoring.git

#Step 4. Browse to mssql-monitoring/influxdb
printf "\r\nStep 4. Browse to mssql-monitoring/influxdb\r\n"
cd mssql-monitoring/influxdb

#Step 5. Edit run.sh and change the variables to match your environment
printf "\r\nStep 5. Edit run.sh and change the variables to match your environment\r\n"
# By default, this will run without modification, but if you want to change where the data directory gets mapped, you can do that here
# Make sure this folder exists on the host.
# This directory from the host gets passed through to the docker container.
#INFLUXDB_HOST_DIRECTORY="/mnt/influxdb"
 
# This is where the mapped host directory get mapped to in the docker container.
#INFLUXDB_GUEST_DIRECTORY="/host/influxdb"
mkdir -p /mnt/influxdb
mkdir -p /host/influxdb

#Step 6. Execute run.sh. This will pull down the mssql-monitoring-InfluxDB image and create and run the container
printf "\r\nStep 6. Execute run.sh. This will pull down the mssql-monitoring-InfluxDB image and create and run the container\r\n"
chmod +x run.sh
./run.sh
