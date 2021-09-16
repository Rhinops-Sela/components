import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.dirname(__file__))
grafana_url = execution.local_parameters['GRAFANA_DNS_RECORD']
template_path = os.path.join(
    execution.templates_folder, "monitoring-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()

grafana_chart = Helm(os.path.dirname(__file__), "monitoring", "grafana")
values_file_path = os.path.join(
    execution.execution_folder, "values.yaml")
grafana_chart.install_chart(release_name="stable",
                                  chart_url="https://kubernetes-charts.storage.googleapis.com",
                                  additional_values=[f"--values {values_file_path}"])
core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.add_records(f"{grafana_url}=grafana.monitoring.svc.cluster.local")
partial_command = "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}'"
command = f"{partial_command} | base64 --decode > '{execution.output_folder}/grafana.out'2>&1"
execution.run_command(command, show_output=False)
