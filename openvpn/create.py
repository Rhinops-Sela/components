import os
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

working_folder = os.path.join(os.getcwd(), "openvpn")
execution  = Execution(working_folder)
template_path = os.path.join(execution.templates_folder, "vpn-ng-template.json")
nodegroup = Nodegroup(working_folder, template_path)
nodegroup.create()

openvpn_chart = Helm(working_folder, "openvpn")
values_file_path = os.path.join(
    execution.execution_folder, "values.yaml")
openvpn_chart.install(release_name="stable",  chart_url="http://storage.googleapis.com/kubernetes-charts",
             additional_values=[f"--values {values_file_path}"])
execution.run_command(f"./keygen/generate-client-key.sh {execution.local_parameters['USERS']} openvpn openvpn {execution.output_folder} 2>&1 | Out-Null")

