
from fennec_execution.execution import Execution
import os

from fennec_helpers.helper import Helper


class Nodegroup():
    def __init__(self, execution: Execution, node_group_name: str = "", template_path=""):
        self.template_path = template_path if template_path else os.path.join(os.path.dirname(
            os.path.realpath(__file__)), "templates", "generic-nodegrpup.json")
        self.template = Helper.file_to_object(self.template_path)
        self.nodegroup = self.template['nodeGroups'][0]
        self.execution = execution
        if node_group_name:
            self.nodegroup['name'] = node_group_name
        self.template['metadata']['name'] = execution.cluster_name
        self.template['metadata']['region'] = execution.cluster_region

    def create(self):
        self.execution.run_command(
            f"eksctl create nodegroup -f {self.__create_execution_file__()}", kubeconfig=False)

    def delete(self):
        self.execution.run_command(
            f"eksctl delete nodegroup -f {self.__create_execution_file__()}  --approve", kubeconfig=False)

    def __create_execution_file__(self) -> str:
        self.template['nodeGroups'][0] = self.nodegroup
        execution_file = os.path.join(
            self.execution.working_folder, "nodegroup-execute.json")
        Helper.str_to_file(str(self.template), execution_file)
        return execution_file

    def add_instance_types(self, instance_types: str):
        for instance_type in instance_types.split(','):
            self.nodegroup['instancesDistribution']['instanceTypes'].append(
                instance_type)

    def add_taints(self, taints: str):
        if not taints:
            return
        modified_nodegroup = Nodegroup.add_properties(
            "taints", taints, self.nodegroup)
        for taint in taints.split(';'):
            self.add_tags(
                f'k8s.io/cluster-autoscaler/node-template/taint/{taint.split("=")[0]}=true:NoSchedule')
        self.nodegroup = modified_nodegroup

    def add_labels(self, labels: str):
        if not labels:
            return
        modified_nodegroup = Nodegroup.add_properties(
            "labels", labels, self.nodegroup)
        for label in labels.split(';'):
            self.add_tags(
                f'k8s.io/cluster-autoscaler/node-template/{label.split("=")[0]}={label.split("=")[1]}')
        self.nodegroup = modified_nodegroup

    def add_tags(self, tags: str):
        if not tags:
            return
        modified_nodegroup = Nodegroup.add_properties(
            "tags", tags, self.nodegroup)
        self.nodegroup = modified_nodegroup

    def set_spot_properties(self, on_demand_base_capacity='0', on_demand_percentage_above_base_capacity='0', spot_allocation_strategy="lowest-price"):
        instances_distribution = self.nodegroup['instancesDistribution']
        instances_distribution = self.add_properties('onDemandBaseCapacity',
                                                     on_demand_base_capacity, instances_distribution)
        instances_distribution = self.nodegroup['instancesDistribution']
        instances_distribution = self.add_properties('onDemandPercentageAboveBaseCapacity',
                                                     on_demand_percentage_above_base_capacity, instances_distribution)
        instances_distribution = self.nodegroup['instancesDistribution']
        instances_distribution = self.add_properties('spotAllocationStrategy',
                                                     spot_allocation_strategy, instances_distribution)
        self.nodegroup['instancesDistribution'] = instances_distribution

    @staticmethod
    def add_properties(prop_to_add: str, prop_values: str, working_object):
        if not prop_to_add in working_object:
            working_object[prop_to_add] = {}
        for tag in str(prop_values).split(';'):
            porp_holder = working_object[prop_to_add]
            if '=' in tag:
                porp_holder[tag.split('=')[0]] = f"{tag.split('=')[1]}"
            else:
                working_object[prop_to_add] = prop_values
        return working_object
