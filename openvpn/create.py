import os
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution  = Execution(os.path.dirname(__file__))
template_path = os.path.join(execution.templates_folder, "vpn-ng-template.json")
nodegroup = Nodegroup(os.path.dirname(__file__), template_path)
nodegroup.create()
openvpn_chart = Helm(os.path.dirname(__file__), "openvpn")
values_file_path = os.path.join(
    execution.execution_folder, "values.yaml")
openvpn_chart.create_namespace("openvpn")
openvpn_chart.install_file(file = os.path.join(os.path.dirname(__file__), "prerequisites", "openvpn-pv-claim.yaml"), namespace = "openvpn")
openvpn_chart.install_chart(release_name="stable",  chart_url="http://storage.googleapis.com/kubernetes-charts",
             additional_values=[f"--values {values_file_path}"])
keygen_script_path = os.path.join(os.path.dirname(__file__), "keygen", "generate-client-key.sh")
execution.run_command(f'{keygen_script_path} "{execution.local_parameters["USERS"]}" openvpn openvpn {execution.output_folder} 2>&1')

