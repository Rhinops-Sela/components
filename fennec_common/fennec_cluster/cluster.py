
from fennec_execution.execution import Execution
import os


class Cluster:
    def __init__(self, execution: Execution) -> None:
        self.execution = execution

    def check_if_cluster_exists(self) -> bool:
        command = 'eksctl get clusters -o json'
        clusters = self.execution.run_command(command, show_output=False).log
        clusters_object = Execution.json_to_object(clusters)
        for cluster in clusters_object:
            if cluster['name'] == self.execution.cluster_name and cluster['region'] == self.execution.cluster_region:
                return True
        return False

    def create(self):
        if self.check_if_cluster_exists():
            print(
                f"Cluster {self.execution.cluster_name} already exists in region {self.execution.cluster_region}")
            return True
        cluster_file = os.path.join(
            self.execution.templates_folder, "00.cluster", "cluster.json")
        command = f'eksctl create cluster -f "{cluster_file}"'
        result = self.execution.run_command(command)
        if not result:
            Execution.exit(1, result.log)
