import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.dirname(__file__))
redis_url = execution.local_parameters['REDIS_DNS_RECORD']
redis_admin_url = execution.local_parameters['REDIS_ADMIN_DNS_RECORD']
namespace = execution.local_parameters['NAMESPACE']
template_path = os.path.join(
    execution.templates_folder, "redis-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()

helm_chart = Helm(os.path.dirname(__file__), namespace=namespace, chart_name="redis")
values_file_path = os.path.join(
    execution.execution_folder, "values.json")

values_file_object = Helper.file_to_object(values_file_path)
values_file_object['master']['extraFlags'] = str(execution.local_parameters['EXTRA_FLAGS']).split(',')
values_file_object['cluster']['slaveCount'] = execution.local_parameters['NUMBER_SLAVES']

if execution.local_parameters['DISABLED_COMMANDS']:
    values_file_object['master']['disableCommands'] = execution.local_parameters['DISABLED_COMMANDS'].split(',')
    values_file_object['slave']['disableCommands'] = execution.local_parameters['DISABLED_COMMANDS'].split(',')

execution_file = os.path.join(
    os.path.dirname(__file__), "redis-execute.values.json")
Helper.to_json_file(values_file_object, execution_file)    

helm_chart.install_chart(release_name="bitnami",
                                  chart_url="https://charts.bitnami.com/bitnami",
                                  additional_values=[f"--values {execution_file}"])
core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.add_records(f"{redis_url}=redis-headless.{namespace}.svc.cluster.local;{redis_admin_url}=redis-ui.{namespace}.svc.cluster.local")

ui_foler = os.path.join(execution.execution_folder, 'ui')
admin_deployment = os.path.join(ui_foler, 'deployment.json')
admin_file_object = Helper.file_to_object(admin_deployment)
admin_file_object['spec']['template']['spec']['containers'][0]['env'][0]['value'] = redis_url
execution_file = os.path.join(
    os.path.dirname(__file__), "redis-admin-execute.values.json")
Helper.to_json_file(admin_file_object, execution_file)   
helm_chart.install_folder(base_folder=execution.execution_folder ,folder='ui/deployment.json', namespace=namespace)