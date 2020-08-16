import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

execution = Execution(os.path.dirname(__file__))
es_url = execution.local_parameters['ES_DNS_RECORD']

namespace = execution.local_parameters['NAMESPACE']
core_dns = CoreDNS(os.path.join(os.getcwd(), "core-dns"))
core_dns.delete_records(f"{es_url}=elasticsearch-master.{namespace}.svc.cluster.local")
elasticsearch_chart = Helm(os.path.dirname(__file__), "elasticsearch")
elasticsearch_chart.uninstall_chart()
if execution.local_parameters['INSTALL_KIBANA']:
    kibana_url = execution.local_parameters['KIBANA_DNS_RECORD']
    core_dns.delete_records(f"{kibana_url}=kibana-kibana.{namespace}.svc.cluster.local")
    kibana_chart = Helm(os.path.dirname(__file__), "kibana")
    kibana_chart.uninstall_chart()


