import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

working_folder = os.path.join(os.getcwd(), "grafana")
execution = Execution(working_folder)
grafana_chart = Helm(working_folder, "monitoring", "grafana")
grafana_chart.uninstall_chart()
core_dns = CoreDNS(working_folder)
grafana_url = execution.local_parameters['GRAFANA_DNS_RECORD']
core_dns.delete_records(f"{grafana_url}=grafana.monitoring.svc.cluster.local")