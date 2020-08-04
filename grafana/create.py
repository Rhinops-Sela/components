import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

working_folder = os.path.join(os.getcwd(), "grafana")
execution = Execution(working_folder)
grafana_url = execution.local_parameters['GRAFANA_DNS_RECORD']
template_path = os.path.join(
    execution.templates_folder, "monitoring-ng-template.json")
nodegroup = Nodegroup(working_folder, template_path)
nodegroup.create()

grafana_chart = Helm(working_folder, "monitoring", "grafana")
values_file_path = os.path.join(
    execution.execution_folder, "values.yaml")
grafana_chart.install_chart(release_name="stable",
                                  chart_url="https://kubernetes-charts.storage.googleapis.com",
                                  additional_values=[f"--values {values_file_path}"])
core_dns = CoreDNS(working_folder)
core_dns.add_records(f"{grafana_url}=grafana.monitoring.svc.cluster.local")
partial_command = "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}'"
command = f"{partial_command} | base64 --decode > '{execution.output_folder}/grafana.out'2>&1"
execution.run_command(command, show_output=False)
