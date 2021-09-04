import os
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.dirname(__file__))
namespace = execution.local_parameters['NAMESPACE']
kafka_url = execution.local_parameters['KAFKA_DNS_RECORD']
template_path = os.path.join(
    execution.templates_folder, "kafka-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()

kafka_chart = Helm(os.path.dirname(__file__), namespace=namespace, chart_name="bitnami/kafka")
values_file_path = os.path.join(
    execution.execution_folder, "kafka-values.json")
values_file_object = Helper.file_to_object(values_file_path)
values_file_object['cp-kafka']['brokers'] = execution.local_parameters['BROKERS']
values_file_object['cp-kafka']['imageTag'] = execution.local_parameters['KAFKA_IMAGE_TAG']
values_file_object['cp-zookeeper']['enabled'] = execution.local_parameters['INSTALL_ZOOKEEPER']
values_file_object['cp-zookeeper']['imageTag'] = execution.local_parameters['ZOOKEEPR_IMAGE_TAG']
execution_file = os.path.join(
    os.path.dirname(__file__), "kafka-execute.values.json")
Helper.to_json_file(values_file_object, execution_file)
kafka_chart.install_chart(release_name="kafka",
                                  chart_url="https://charts.bitnami.com/bitnami",
                                  additional_values=[f"--values {execution_file}"], 
                                  timeout = 360)
#core_dns = CoreDNS(os.path.dirname(__file__))
#core_dns.add_records(f"{kafka_url}=elasticsearch-master.{namespace}.svc.cluster.local")
#if execution.local_parameters['INSTALL_ZOOKEEPER']:                                  
    #core_dns.add_records(f"{kafka_url}=elasticsearch-master.{namespace}.svc.cluster.local")
