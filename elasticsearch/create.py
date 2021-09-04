import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.dirname(__file__))
namespace = execution.local_parameters['NAMESPACE']
es_url = execution.local_parameters['ES_DNS_RECORD']
template_path = os.path.join(
    execution.templates_folder, "elk-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()

elasticsearch_chart = Helm(os.path.dirname(__file__), namespace=namespace, chart_name="elasticsearch")
values_file_path = os.path.join(
    execution.execution_folder, "es-values.json")
values_file_object = Helper.file_to_object(values_file_path)
values_file_object['replicas'] = execution.local_parameters['REPLICAS']
values_file_object['minimumMasterNodes'] = execution.local_parameters['NUMBER_MASTERS']
execution_file = os.path.join(
    os.path.dirname(__file__), "elasticsearch-execute.values.json")
Helper.to_json_file(values_file_object, execution_file)
elasticsearch_chart.install_chart(release_name="elastic",
                                  chart_url="https://helm.elastic.co",
                                  additional_values=[f"--values {execution_file}"], 
                                  timeout = 360)
core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.add_records(f"{es_url}=elasticsearch-master.{namespace}.svc.cluster.local")

if execution.local_parameters['INSTALL_KIBANA']:
    kibana_chart = Helm(os.path.dirname(__file__), namespace, "kibana")
    kibana_url = execution.local_parameters['KIBANA_DNS_RECORD']
    values_file_path = os.path.join(
        execution.execution_folder, "kibana-values.json")
    values_file_object = Helper.file_to_object(values_file_path)
    values_file_object[
        'elasticsearchHosts'] = f"http://{es_url}:9200"
    execution_file = os.path.join(
        os.path.dirname(__file__), "kibana-execute.values.json")
    Helper.to_json_file(values_file_object, execution_file)
    kibana_chart.install_chart(release_name="elastic",
                                      chart_url="https://helm.elastic.co",
                                      additional_values=[f"--values {execution_file}"])
    core_dns.add_records(f"{kibana_url}=kibana-kibana.{namespace}.svc.cluster.local")
