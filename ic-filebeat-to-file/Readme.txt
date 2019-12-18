commands to deploy helm chart for filebeat

#To install filebeat and deploy filebeat in kube-system namespace
cd ./ic-filebeat-to-file/
helm upgrade --install ic-filebeat ./. --force --namespace "kube-system"

#To delete helm chart
#ic-filebeat is the release name
helm del --purge ic-filebeat

#To list helm charts
helm list


