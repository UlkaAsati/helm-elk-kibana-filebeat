#--------------------------------------------------------------------------------------------------------------
# Shell Script Name: mssql_dbcertificate_secondary
# Summary: Following things are handled by the Shell script :
# Creates a db certificate on secondary nodes. Also creates db mirroring endpoints.
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

# create certificate on secondary servers

if [[ "$HOSTNAME" = $SQL_NODE2 ||  "$HOSTNAME" = $SQL_NODE3 ]]; then

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD << EOF

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$SQL_PASSWORD';
GO
CREATE CERTIFICATE dbm_certificate AUTHORIZATION dbm_user FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer' WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/dbm_certificate.pvk', DECRYPTION BY PASSWORD = '$SQL_PASSWORD');
GO
QUIT
EOF

fi

#Create the database mirroring endpoints

sqlcmd -S localhost -U $SQL_USERNAME -P $SQL_PASSWORD << EOF
CREATE ENDPOINT [Hadr_endpoint] AS TCP (LISTENER_PORT = 5022) FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE dbm_certificate, ENCRYPTION = REQUIRED ALGORITHM AES); 
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];
GO
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GO
QUIT
EOF

echo "database mirroring endpoint created"
