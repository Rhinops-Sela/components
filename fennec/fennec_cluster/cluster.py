import os
from fennec_executers.base_executer import Kubectl
from fennec_helpers import Helper
from fennec_execution import Execution

class Cluster(Kubectl):
    def __init__(self, execution: Execution) -> None:
        Kubectl.__init__(self, execution)

    def check_if_cluster_exists(self) -> bool:
        command = 'eksctl get clusters -o json'
        clusters = self.execution.run_command(
            command, show_output=False, kubeconfig=False).log
        clusters_object = Helper.json_to_object(clusters)
        for cluster in clusters_object:
            if cluster['name'] == self.execution.cluster_name and cluster['region'] == self.execution.cluster_region:
                return True
        return False

    def create(self):
        if self.check_if_cluster_exists():
            print(
                f"Cluster {self.execution.cluster_name} already exists in region {self.execution.cluster_region}")
            return
        cluster_file = os.path.join(
            self.execution.templates_folder, "00.cluster", "cluster.json")
        command = f'eksctl create cluster -f "{cluster_file}"'
        self.execution.run_command(command, kubeconfig=False)
        self.execution.create_kubernetes_client()

    def delete(self):
        if not self.check_if_cluster_exists():
            print(
                f"Cluster {self.execution.cluster_name} doesn't exist in region {self.execution.cluster_region}")
            return
        cluster_file = os.path.join(
            self.execution.templates_folder, "00.cluster", "cluster.json")
        command = f'eksctl delete cluster -f "{cluster_file}"'
        self.execution.run_command(command, kubeconfig=False)
