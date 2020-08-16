import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.dirname(__file__))
prometheus_url = execution.local_parameters['PROMETHEUS_DNS_RECORD']
alertmanager_url = execution.local_parameters['ALERTMANAGER_DNS_RECORD']
template_path = os.path.join(
    execution.templates_folder, "monitoring-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()

values_file_path = os.path.join(
    execution.execution_folder, "values.json")
values_file_object = Helper.file_to_object(values_file_path)
if execution.local_parameters['EMAIL_NOTIFER'] == True:
    values_file_object['alertmanagerFiles']['alertmanager.yml']['receivers'].append({
        "name": "email-alert",
        "email_configs": [
            {
                "to":  execution.local_parameters["TO"],
                "from":  execution.local_parameters["FROM"],
                "smarthost":  f'{execution.local_parameters["SMTP_SERVER"]}:587',
                "auth_username":  execution.local_parameters["USERNAME"],
                "auth_identity":  execution.local_parameters["FROM"],
                "auth_password":  execution.local_parameters["PASSWORD"]
            }
        ]
    })
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['routes'] += {
        "receiver": "email-alert", "group_wait": "10s", "match_re": {
            "severity": "error|warning"
        },
        "continue": True}
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['receiver'] = "email-alert"    
if execution.local_parameters['SLACK_NOTIFER'] == True:
    values_file_object['alertmanagerFiles']['alertmanager.yml']['receivers'].append({
        "name": "slack-alert",
        "slack_configs": [
            {
                "api_url": execution.local_parameters["SLACK_URL"],
                "send_resolved": True,
                "channel": "#alerts",
                "text": "{{ range .Alerts }}<!channel> {{ .Annotations.summary }}\n{{ .Annotations.description }}\n{{ end }}"
            }
        ]
    })
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['routes'].append({
        "receiver": "slack-alert",
        "group_wait": "10s",
        "match_re": {
            "severity": "error|warning"
        },
        "continue": True
    })
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['receiver'] = "slack-alert"

if execution.local_parameters['WEBHOOK_NOTIFER'] == True:
    values_file_object['alertmanagerFiles']['alertmanager.yml']['receivers'].append({
        "name": "webhooks-alert",
        "webhook_configs": [
            {
                "url": execution.local_parameters["WEBHOOK_URL"]
            }
        ]
    })
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['routes'].append({
        "receiver": "webhooks-alert",
        "group_wait": "10s",
        "match_re": {
            "severity": "error|warning"
        },
        "continue": True
    })
    values_file_object['alertmanagerFiles']['alertmanager.yml']['route']['receiver'] = "webhooks-alert"
execution_file = os.path.join(
    os.path.dirname(__file__), "prometheus-execute.values.json")
fixed_values_file_object = values_file_object
for rule in values_file_object['serverFiles']['alerting_rules.yml']['groups'][0]['rules']:
    rule['expr'] = rule['expr'].replace('"','\\\"')
Helper.to_json_file(values_file_object, execution_file)
prometheus_chart = Helm(os.path.dirname(__file__), "monitoring", "prometheus")
prometheus_chart.install_chart(release_name="stable",
                               chart_url="https://kubernetes-charts.storage.googleapis.com",
                               additional_values=[f"--values {values_file_path}"])
core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.add_records(f"{prometheus_url}=prometheus-server.monitoring.svc.cluster.local")
core_dns.add_records(f"{alertmanager_url}=prometheus-alertmanager.monitoring.svc.cluster.local")