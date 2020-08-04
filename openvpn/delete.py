import os
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

working_folder = os.path.join(os.getcwd(), "openvpn")
execution = Execution(working_folder)
template_path = os.path.join(
    execution.templates_folder, "vpn-ng-template.json")


openvpn_chart = Helm(working_folder, "openvpn")
openvpn_chart.uninstall_file(os.path.join(working_folder, "prerequisites", "openvpn-pv-claim.yaml"), "openvpn")
openvpn_chart.delete_namespace("openvpn")
nodegroup = Nodegroup(working_folder, template_path)
nodegroup.delete()
