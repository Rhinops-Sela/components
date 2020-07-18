import os
from os import name
from fennec_cluster.cluster import Cluster
from fennec_core_dns.core_dns import CoreDNS
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper

working_folder = os.path.join(os.getcwd(), "cluster")

execution = Execution(working_folder)
cluster = Cluster(working_folder)
cluster.create()
core_dns = CoreDNS(working_folder)
core_dns.reset()

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
content = Helper.replace_in_file(
    arn_template, arn_output, values_to_replace)
cluster.patch_file(content, "kube-system", "configmap/aws-auth")

# Install HPA
install_HPA = execution.local_parameters['INSTALL_CLUSTER_HPA']
if install_HPA:
    hpa_instsllation = os.path.join(
        execution.templates_folder, "03.hpa", "hpa.yaml")
    cluster.create_namespace("horizontal-pod-scaler")
    cluster.install_file(hpa_instsllation, "horizontal-pod-scaler")


# Install Cluster auto scaler
install_cluster_autoscaler = execution.local_parameters['INSTALL_CLUSTER_AUTOSCALER']
if install_cluster_autoscaler:
    cluster_auto_scaler_chart = Helm(working_folder, "cluster-autoscaler")
    values_file_path = os.path.join(
        execution.templates_folder, "04.cluster-autoscaler", "auto_scaler.yaml")
    cluster_auto_scaler_chart.install(release_name="stable", chart_url="https://kubernetes-charts.storage.googleapis.com",
                 additional_values=[
                     f"--values {values_file_path}",
                     f"--set autoDiscovery.clusterName={execution.cluster_name}",
                     f"--set awsRegion={execution.cluster_region}",
                     "--version 7.0.0"
                 ])

# Install Nginx Controller
install_ingress_controller = execution.local_parameters['INSTALL_INGRESS_CONTROLER']
if install_ingress_controller:
    nginx_chart = Helm(working_folder, "nginx-ingress")
    values_file_path = os.path.join(
        execution.templates_folder, "06.nginx", "nginx_values.yaml")
    nginx_chart.install(release_name="stable", additional_values=[
                 f"--values {values_file_path}"])

 # Install cert-manager
cert_manater_chart = Helm(working_folder, "cert-manager")
values_file_path = os.path.join(
    execution.templates_folder, "05.cert-manager", "cert-manager_values.yaml")
cert_manater_chart.install(release_name="jetstack",  chart_url="https://charts.jetstack.io",
             additional_values=[f"--values {values_file_path}"])

cluster.install_folder(folder = os.path.join(
    execution.templates_folder, '05.cert-manager', "kubectl"), namespace = "cert-manager")

# Install Cluster dashboard
install_cluster_dashboard = execution.local_parameters['INSTALL_CLUSTER_DASHBOARD']
if install_cluster_dashboard:
    values_file_path = os.path.join(
        execution.templates_folder, "07.dashboard", "ingress.yaml")
    values_file_path_execution = os.path.join(
        execution.templates_folder, "07.dashboard", "ingress-execute.yaml")
    user_url = execution.local_parameters['CLUSTER_DASHBOARD_URL']
    values_to_replace = {'dashboard.fennec.io': f'{user_url}'}
    Helper.replace_in_file(
        values_file_path, values_file_path_execution, values_to_replace)
    deployment_folder = os.path.join(
        execution.templates_folder, "07.dashboard")
    cluster.install_folder(deployment_folder) 
cluster.export_secret(secret_name="admin-user",
                      namespace="kube-system",
                      output_file_name="dashboard")
