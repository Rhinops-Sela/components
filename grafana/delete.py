import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

execution = Execution(os.path.dirname(__file__))
grafana_chart = Helm(os.path.dirname(__file__), "monitoring", "grafana")
grafana_chart.uninstall_chart()
core_dns = CoreDNS(os.path.dirname(__file__))
grafana_url = execution.local_parameters['GRAFANA_DNS_RECORD']
core_dns.delete_records(f"{grafana_url}=grafana.monitoring.svc.cluster.local")