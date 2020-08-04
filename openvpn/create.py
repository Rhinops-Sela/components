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
openvpn_chart.create_namespace("openvpn")
openvpn_chart.install_file(file = os.path.join(working_folder, "prerequisites", "openvpn-pv-claim.yaml"), namespace = "openvpn")
openvpn_chart.install_chart(release_name="stable",  chart_url="http://storage.googleapis.com/kubernetes-charts",
             additional_values=[f"--values {values_file_path}"])
keygen_script_path = os.path.join(working_folder, "keygen", "generate-client-key.sh")
execution.run_command(f'{keygen_script_path} "{execution.local_parameters["USERS"]}" openvpn openvpn {execution.output_folder} 2>&1')

