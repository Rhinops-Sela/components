from fennec_core_dns.core_dns import CoreDNS
import os
from fennec_executers.kubectl_executer import Kubectl
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

template_path = os.path.join(
    os.path.dirname(__file__), "execution/templates", "dynamo-ng-template.json")
kubectl = Kubectl(os.path.dirname(__file__))


values_to_replace = {
    'DYNAMO_ENDPOINT': f'{kubectl.execution.local_parameters["NAMESPACE"]}'}
ui_deployment_template = os.path.join(
    kubectl.execution.templates_folder, "admin", "01.deployment.json")
ui_deployment_template_output = os.path.join(
    kubectl.execution.templates_folder, "admin", "01.deployment-execute.json")
content = Helper.replace_in_file(
    ui_deployment_template, ui_deployment_template_output, values_to_replace)

kubectl.uninstall_folder(os.path.join(
    kubectl.execution.templates_folder, "dynamodb"), "dynamodb")
kubectl.uninstall_folder(os.path.join(
    kubectl.execution.templates_folder, "admin"), "dynamodb")

core_dns = CoreDNS(os.path.dirname(__file__))
admin_record  = f"{core_dns.execution.local_parameters['ADMIN_DNS_RECORD']}=dynamodb-local-admin.{core_dns.execution.local_parameters['NAMESPACE']}.svc.cluster.local"
dynamo_record  = f"{core_dns.execution.local_parameters['DYNAMO_DNS_RECORD']}=dynamodb-local.{core_dns.execution.local_parameters['NAMESPACE']}.svc.cluster.local"
dns_records = f"{admin_record};{dynamo_record}"
core_dns.delete_records(dns_records=dns_records)
