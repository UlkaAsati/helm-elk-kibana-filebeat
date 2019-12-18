commands to deploy helm chart for logstash

#create new namespace "logging-01 (kibana and logstash will be under logging-01 namespace)
kubectl create ns logging-01

#To install and deploy logstash 
helm upgrade --install ic-logstash ic-logstash\ --force --namespace "logging-102" --set-string elasticsearch.hosts=https://28c8c87b-e96c-41f3-881d-22f5c5ee8d45.b2b5a92ee2df47d58bad0fa448c15585.databases.appdomain.cloud:32098 --set-string elasticsearch.username=ibm_cloud_ace71250_4ce7_4c2f_8c11_49a8d53f4935 --set-string elasticsearch.password=9fab6c96541a13cac039b4e68bd90aeb51d9d3ca5039c03f3d124596d4d62ab1 --set-string elasticsearch.index="max-log-%{+YYYY.MM.dd}"


#To delete helm chart
helm del --purge ic-logstash

#To list helm charts
helm list


