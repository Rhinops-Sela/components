# pip3 install -e /Users/iliagerman/Work/Sela/env_creator/components/fennec_common
import os
from fennec_cluster.cluster import Cluster
from fennec_core_dns.core_dns import CoreDNS
from fennec_execution import Execution
from fennec_helm.helm import Helm
from fennec_namespace import Namespace

execution = Execution(os.path.join(os.getcwd(), "cluster"))
cluster = Cluster(execution)
cluster.create()
core_dns = CoreDNS(execution)
core_dns.reset(os.path.join(execution.templates_folder,
                            "01.coredns", "configmap.yaml"))

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
content = Execution.replace_in_file(
    arn_template, arn_output, values_to_replace)
result = execution.run_command(
    f"kubectl patch configmap/aws-auth -n kube-system --patch '{content}'")

# Install HPA
install_HPA = execution.local_parameters['INSTALL_CLUSTER_HPA']
if install_HPA:
    hpa_instsllation = os.path.join(
        execution.templates_folder, "04.hpa", "hpa.yaml")
    Namespace.create(execution, "horizontal-pod-scaler")
    execution.run_command(f"kubectl apply -f {hpa_instsllation}")


# Install Cluster auto scaler
install_cluster_autoscaler = execution.local_parameters['INSTALL_CLUSTER_AUTOSCALER']
if(install_cluster_autoscaler):
    helm = Helm(execution, "cluster-autoscaler", "stable/cluster-autoscaler",
                "https://kubernetes-charts.storage.googleapis.com")
    values_file_path = os.path.join(
        execution.templates_folder, "05.cluster_autoscaler", "auto_scaler.yaml")
    helm.install_chart("cluster-autoscaler",
                       [
                           f"--values {values_file_path}",
                           f"--set autoDiscovery.clusterName={execution.cluster_name}",
                           f"--set awsRegion={execution.cluster_region}",
                           f"--version 7.0.0"
                       ])

# Install Nginx Controller
install_ingress_controller = execution.local_parameters['INSTALL_INGRESS_CONTROLER']
if(install_ingress_controller):
    helm = Helm(execution, "nginx-ingress", "stable/nginx-ingress")
    values_file_path = os.path.join(
        execution.templates_folder, "06.nginx", "values.yaml")
    helm.install_chart("nginx-ingress", [f"--values {values_file_path}"])

# Install Cluster dashboard
install_cluster_dashboard = execution.local_parameters['INSTALL_CLUSTER_DASHBOARD']
if(install_cluster_dashboard):
    pass
