#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_createAG
# Summary: Following things are handled by the Shell script :
# Creates sql availability group (AG). Creates db on primary node and sync with secondary nodes
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

#Create the AG

if [ "$HOSTNAME" = $SQL_NODE1 ]; then

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "CREATE AVAILABILITY GROUP [ag1] WITH (DB_FAILOVER = ON, CLUSTER_TYPE = EXTERNAL) FOR REPLICA ON N'$SQL_NODE1' WITH ( ENDPOINT_URL = N'tcp://$SQL_NODE1:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = EXTERNAL, SEEDING_MODE = AUTOMATIC), N'$SQL_NODE2' WITH ( ENDPOINT_URL = N'tcp://$SQL_NODE2:5022',  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = EXTERNAL, SEEDING_MODE = AUTOMATIC), N'$SQL_NODE3' WITH( ENDPOINT_URL = N'tcp://$SQL_NODE3:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = EXTERNAL, SEEDING_MODE = AUTOMATIC)";

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE";

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

fi


# Join secondary replicas to the AG.
if [ $? -eq 0 ]; then
	if [[ "$HOSTNAME" =  $SQL_NODE2 ||  "$HOSTNAME" =  $SQL_NODE3 ]]; then

		sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "ALTER AVAILABILITY GROUP [ag1] JOIN WITH (CLUSTER_TYPE = EXTERNAL)";

		sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"

		sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE";

		sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD -Q "GO"


	fi

fi

#create database
if [ $? -eq 0 ]; then
if [ "$HOSTNAME" = $SQL_NODE1 ]; then

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD << EOF
CREATE DATABASE [db1];
GO
ALTER DATABASE [db1] SET RECOVERY FULL;
GO
BACKUP DATABASE [db1] TO DISK = N'/var/opt/mssql/data/db1.bak';
GO

ALTER AVAILABILITY GROUP [ag1] ADD DATABASE [db1];
GO

QUIT

EOF
fi
fi

#join database on secondary replicas

if [ $? -eq 0 ]; then
if [[ "$HOSTNAME" = $SQL_NODE2 ||  "$HOSTNAME" = $SQL_NODE3 ]]; then

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD << EOF

SELECT * FROM sys.databases WHERE name = 'db1';
GO
SELECT DB_NAME(database_id) AS 'database', synchronization_state_desc FROM sys.dm_hadr_database_replica_states;

QUIT
EOF

fi
fi

