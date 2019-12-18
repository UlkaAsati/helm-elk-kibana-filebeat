#-------------------------------------------------------------------------------------
# Shell Script Name: SqlServerInstallScript.sh
# Summary: Following things are handled by the Shell script :
# Install and Configure MsSQL, sqlcmd. It also enables AlwaysOn availability groups
#
# Script Owner : AptData Squad
#---------------------------------------------------------------------------------------


set -e

#=====================================
# SQL Server 2017 Unattended Install
#=====================================
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list)"
sudo apt-get update
sudo apt-get install -y mssql-server
sudo MSSQL_PID=Developer ACCEPT_EULA=Y MSSQL_SA_PASSWORD='@pttusPassword*ReplaceM3!' /opt/mssql/bin/mssql-conf -n setup
touch $HOME/sqlserver_status.txt
systemctl status mssql-server >>$HOME/sqlserver_status.txt

cat $HOME/sqlserver_status.txt

#=====================================
# Install Full-Text Search
#=====================================
sudo apt-get update
sudo apt-get install -y mssql-server-fts

#=====================================
# Install SQL Server Integration Services (SSIS)
#=====================================
sudo apt-get update
sudo apt-get install -y mssql-server-is
sudo SSIS_PID=Developer ACCEPT_EULA=Y /opt/ssis/bin/ssis-conf -n setup
export PATH=/opt/ssis/bin:$PATH

#=====================================
# Enable SQL Server Agent on Linux
#=====================================
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
sudo systemctl restart mssql-server.service

#sudo systemctl status mssql-server.service

#Import the public repository GPG keys.
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

#Register the Microsoft Ubuntu repository.

curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

# Update the sources list and run the installation command with the unixODBC developer package.
sudo apt-get update

sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile

echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
. ~/.bashrc

ln -sfn /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd


sqlcmd -S localhost -U SA -P '@pttusPassword*ReplaceM3!' -Q "CREATE DATABASE TestDB"
sqlcmd -S localhost -U SA -P '@pttusPassword*ReplaceM3!' -Q "GO"


#Enable AlwaysOn availability groups and restart mssql-server

sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
sudo systemctl restart mssql-server

#sudo systemctl status mssql-server

#create user

sqlcmd -S localhost -U SA -P '@pttusPassword*ReplaceM3!' << EOF
CREATE LOGIN dbm_login WITH PASSWORD = '@pttusPassword*ReplaceM3!';
GO
CREATE USER dbm_user FOR LOGIN dbm_login;
GO
QUIT
EOF
