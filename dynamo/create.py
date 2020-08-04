from fennec_core_dns.core_dns import CoreDNS
import os
from fennec_executers.kubectl_executer import Kubectl
from fennec_helpers.helper import Helper
from fennec_nodegorup.nodegroup import Nodegroup

working_folder = os.path.join(os.getcwd(), "dynamo")
template_path = os.path.join(
    working_folder, "execution/templates", "dynamo-ng-template.json")
nodegroup = Nodegroup(working_folder, template_path)
nodegroup.create()

values_to_replace = {
    'DYNAMO_ENDPOINT': f'{nodegroup.execution.local_parameters["NAMESPACE"]}'}
ui_deployment_template = os.path.join(
    nodegroup.execution.templates_folder, "admin", "01.deployment.json")
ui_deployment_template_output = os.path.join(
    nodegroup.execution.templates_folder, "admin", "01.deployment-execute.json")
content = Helper.replace_in_file(
    ui_deployment_template, ui_deployment_template_output, values_to_replace)

kubectl = Kubectl(working_folder)
kubectl.install_folder(os.path.join(
    nodegroup.execution.templates_folder, "dynamodb"), "dynamodb")
kubectl.install_folder(os.path.join(
    nodegroup.execution.templates_folder, "admin"), "dynamodb")

core_dns = CoreDNS(working_folder)
admin_record  = f"{nodegroup.execution.local_parameters['ADMIN_DNS_RECORD']}=dynamodb-local-admin.{nodegroup.execution.local_parameters['NAMESPACE']}.svc.cluster.local"
dynamo_record  = f"{nodegroup.execution.local_parameters['DYNAMO_DNS_RECORD']}=dynamodb-local.{nodegroup.execution.local_parameters['NAMESPACE']}.svc.cluster.local"
dns_records = f"{admin_record};{dynamo_record}"
core_dns.add_records(dns_records=dns_records)
