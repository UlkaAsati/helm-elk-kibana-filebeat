#-------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_dbcertificate_primary
# Summary: Following things are handled by the Shell script :
# Create a db certificate on primary node and copies it to secondary nodes. assigns the neccessary permissions
#
# Script Owner : AptData Squad
#-------------------------------------------------------------------------------------------------------------

#!/bin/bash

set -e

SQL_NODE1=$1
SQL_NODE2=$2
SQL_NODE3=$3
SQL_USERNAME=$4
SQL_PASSWORD=$5

#create DB certificate only on vm1

if [ "$HOSTNAME" = $SQL_NODE1 ]; then

	if [ -e /var/opt/mssql/data/dbm_certificate.cer ]
	then
		echo "dbm_certificate.cer file exists on $HOSTNAME"
	else

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD << EOF
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$SQL_PASSWORD';
GO
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
GO
BACKUP CERTIFICATE dbm_certificate TO FILE = '/var/opt/mssql/data/dbm_certificate.cer' WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/dbm_certificate.pvk',ENCRYPTION BY PASSWORD = '$SQL_PASSWORD');
GO

QUIT
EOF


cd /var/opt/mssql/data
chown mssql:mssql dbm_certificate.*
fi

#copy to remote host and chnage permissions

	if ssh -i /root/.ssh/ibm_vm2 -o StrictHostKeyChecking=no root@$SQL_NODE2 "test -e /var/opt/mssql/data/dbm_certificate.pvk || test -e /var/opt/mssql/data/dbm_certificate.cer "
	then
		echo "dbm_certificates exists on $SQL_NODE2";
	else
		scp -i /root/.ssh/ibm_vm2 -o  StrictHostKeyChecking=no /var/opt/mssql/data/dbm_certificate.* root@$SQL_NODE2:/var/opt/mssql/data
	fi


	if ssh -i /root/.ssh/ibm_vm2 -o StrictHostKeyChecking=no root@$SQL_NODE3 "test -e /var/opt/mssql/data/dbm_certificate.pvk || test -e /var/opt/mssql/data/dbm_certificate.cer "
	then
		echo "dbm_certificates exists on $SQL_NODE3";
	else
		scp -i /root/.ssh/ibm_vm2 -o  StrictHostKeyChecking=no /var/opt/mssql/data/dbm_certificate.* root@$SQL_NODE3:/var/opt/mssql/data
	fi


else
echo "This is not primary node"

fi


if [[ "$HOSTNAME" =  $SQL_NODE2 ||  "$HOSTNAME" =  $SQL_NODE3 ]]; then

	if  "test -e /var/opt/mssql/data/dbm_certificate.cer"
	then
		echo "dbm_certificate.cer file exists already on $HOSTNAME"
	else
		until [ -f /var/opt/mssql/data/dbm_certificate.cer ]
		do
     		sleep 2
		done
	fi

	if  "test -e /var/opt/mssql/data/dbm_certificate.pvk"
	then
		echo "dbm_certificate.pvk file exists already on $HOSTNAME"		
	else
		until [ -f /var/opt/mssql/data/dbm_certificate.pvk ]
		do
     		sleep 2
		done
	fi

cd /var/opt/mssql/data
chown mssql:mssql dbm_certificate.*

fi
