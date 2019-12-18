commands to deploy helm chart for filebeat

#To install filebeat and deploy filebeat in kube-system namespace
#shell script:
password="ff8a150ce2ea75587af98074f294ebb8523c395352f9aa7c1d9d8873b119d62a"
username="ibm_cloud_29ded3c4_b9e7_4ec0_bb74_49426e297388"
host="https://496df62b-adc6-42d9-b879-f9c77705ce81.bkvfv1ld0bj2bdbncbeg.databases.appdomain.cloud:32217"

cd ./ic-filebeat-to-es/
helm upgrade --install ic-filebeat ./. --force --namespace "kube-system" --set-string elasticsearch.username=${username} --set-string elasticsearch.password=${password} --set-string elasticsearch.index="max-test-log-%{+YYYY.MM.dd}"

#To delete helm chart
helm del --purge ic-filebeat-to-es

#To list helm charts
helm list


