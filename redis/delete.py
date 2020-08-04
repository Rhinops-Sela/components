import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution

working_folder = os.path.join(os.getcwd(), "redis")
execution = Execution(working_folder)
redis_url = execution.local_parameters['REDIS_DNS_RECORD']
redis_admin_url = execution.local_parameters['REDIS_ADMIN_DNS_RECORD']
namespace = execution.local_parameters['NAMESPACE']
helm_chart = Helm(working_folder, namespace=namespace, chart_name="redis")
helm_chart.uninstall_chart()
helm_chart.delete_namespace(namespace)