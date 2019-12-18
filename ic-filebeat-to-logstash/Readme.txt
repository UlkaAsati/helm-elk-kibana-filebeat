commands to deploy helm chart for filebeat

#To install filebeat and deploy filebeat in kube-system namespace

logstashnamespace="logging-01"
logstashservicename="logstash-service"
helm upgrade --install ic-filebeat ./ic-filebeat/ --force --namespace "kube-system" --set-string logstash.namespace=${logstashnamespace} --set-string logstash.servicename=${logstashservicename}

#To delete helm chart
# ic-filebeat is the name of the release
helm del --purge ic-filebeat

#To list helm charts
helm list


