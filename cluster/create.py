# pip3 install -e /Users/iliagerman/Work/Sela/env_creator/components/fennec_common
import os
from fennec_cluster.cluster import Cluster
from fennec_core_dns.core_dns import CoreDNS
from fennec_execution import Execution

execution = Execution(os.path.join(os.getcwd(), "cluster"))
#cluster = Cluster(execution)
# cluster.create()
#core_dns = CoreDNS(execution)
# core_dns.reset(os.path.join(execution.templates_folder,
#                            "01.coredns", "configmap.yaml"))
# Add admin ARN
admin_arn = execution.local_parameters['ADMIN_ARN']
arn_template = os.path.join(
    execution.templates_folder, "02.auth", "aws-auth.yaml")
arn_output = os.path.join(
    execution.templates_folder, "02.auth", "aws-auth-execute.yaml")
admin_arn = execution.local_parameters['ADMIN_ARN']
username = admin_arn.split('/')[1]
values_to_replace = {'ADMIN_USER': f'{admin_arn}',
                     'ADMIN_USERNAME': f'{username}'}
content = Execution.replace_in_file(arn_template, arn_output, values_to_replace)
result = execution.run_command(
    f"kubectl patch configmap/aws-auth -n kube-system --patch '{content}'")
# Install HPA
install_HPA = execution.local_parameters['INSTALL_HPA']
if install_HPA:
    execution.run_command(f"")
