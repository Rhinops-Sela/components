import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

execution = Execution(os.path.dirname(__file__))
kafka_url = execution.local_parameters['KAFKA_DNS_RECORD']

namespace = execution.local_parameters['NAMESPACE']
core_dns = CoreDNS(os.path.join(os.getcwd(), "core-dns"))
core_dns.delete_records(f"{kafka_url}=kafka.{namespace}.svc.cluster.local")
kafka_chart = Helm(os.path.dirname(__file__), "kafka")
kafka_chart.uninstall_chart()
