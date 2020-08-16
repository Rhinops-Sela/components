import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

execution = Execution(os.path.dirname(__file__))
prometheus_url = execution.local_parameters['PROMETHEUS_DNS_RECORD']
alertmanager_url = execution.local_parameters['ALERTMANAGER_DNS_RECORD']
prometheus_chart = Helm(os.path.dirname(__file__), "monitoring", "prometheus")
prometheus_chart.uninstall_chart()
core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.delete_records(
    f"{prometheus_url}=prometheus-server.monitoring.svc.cluster.local;{alertmanager_url}=prometheus-alertmanager.monitoring.svc.cluster.local")
