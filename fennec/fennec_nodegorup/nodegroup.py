
from fennec_execution.execution import Execution
import os

from fennec_helpers.helper import Helper


class Nodegroup():
    def __init__(self, working_folder: str, template_path=""):
        self.execution = Execution(working_folder)
        self.template_path = template_path if template_path else os.path.join(os.path.dirname(
            os.path.realpath(__file__)), "templates", "generic-nodegrpup.json")
        self.template = Helper.file_to_object(self.template_path)
        self.nodegroup = self.template['nodeGroups'][0]
        if "NODEGROUP_NAME" in self.execution.local_parameters:
            self.nodegroup['name'] = self.execution.local_parameters["NODEGROUP_NAME"]
        self.template['metadata']['name'] = self.execution.cluster_name
        self.template['metadata']['region'] = self.execution.cluster_region
        self.__add_instance_types__()

    def create(self):
        self.add_tags()
        self.__add_node_role()
        self.__add_labels__()
        self.__add_taints__()
        self.__set_volume_size()
        self.__set_initial_scale()
        self.__set_min_scale()
        self.__set_max_scale()

        if "USE_SPOT" in self.execution.local_parameters and self.execution.local_parameters['USE_SPOT']:
            self.__set_spot_properties__()
        self.execution.run_command(
            f"eksctl create nodegroup -f {self.__create_execution_file__()}", kubeconfig=False)

    def delete(self):
        self.execution.run_command(
            f"eksctl delete nodegroup -f {self.__create_execution_file__()}  --approve", kubeconfig=False)

    def __create_execution_file__(self) -> str:
        self.template['nodeGroups'][0] = self.nodegroup
        execution_file = os.path.join(
            self.execution.working_folder, "nodegroup-execute.json")
        Helper.to_json_file(self.template, execution_file)
        return execution_file

    def __add_instance_types__(self):
        if not "INSTANCE_TYPES" in self.execution.local_parameters:
            return
        instance_types = self.execution.local_parameters['INSTANCE_TYPES']
        for instance_type in instance_types.split(','):
            self.nodegroup['instancesDistribution']['instanceTypes'].append(
                instance_type)

    def __add_taints__(self):
        if not "TAINTS" in self.execution.local_parameters:
            return
        taints = self.execution.local_parameters['TAINTS']
        modified_nodegroup = Nodegroup.add_properties(
            "taints", taints, self.nodegroup)
        for taint in taints.split(';'):
            self.add_tags(
                f'k8s.io/cluster-autoscaler/node-template/taint/{taint.split("=")[0]}=true:NoSchedule')
        self.nodegroup = modified_nodegroup

    def __add_node_role(self):
        if not "NODE_ROLE" in self.execution.local_parameters:
            return
        labels = f"role={self.execution.local_parameters['NODE_ROLE']}"
        modified_nodegroup = Nodegroup.add_properties(
            "labels", labels, self.nodegroup)
        self.add_tags(
            f'k8s.io/cluster-autoscaler/node-template/{labels.split("=")[0]}={labels.split("=")[1]}')
        self.nodegroup = modified_nodegroup

    def __add_labels__(self):
        if not "LABELS" in self.execution.local_parameters:
            return
        labels = self.execution.local_parameters['LABELS']
        modified_nodegroup = Nodegroup.add_properties(
            "labels", labels, self.nodegroup)
        self.nodegroup = modified_nodegroup

    def __set_volume_size(self):
        if not "NODE_VOLUME_SIZE" in self.execution.local_parameters:
            return
        volume_size = self.execution.local_parameters['NODE_VOLUME_SIZE']
        self.nodegroup["volumeSize"] = volume_size

    def __set_initial_scale(self):
        if not "DESIRED" in self.execution.local_parameters:
            return
        volume_size = self.execution.local_parameters['DESIRED']
        self.nodegroup["desiredCapacity"] = volume_size

    def __set_min_scale(self):
        if not "MIN" in self.execution.local_parameters:
            return
        volume_size = self.execution.local_parameters['MIN']
        self.nodegroup["minSize"] = volume_size

    def __set_max_scale(self):
        if not "MAX" in self.execution.local_parameters:
            return
        volume_size = self.execution.local_parameters['MAX']
        self.nodegroup["maxSize"] = volume_size

    def add_tags(self, tags_custom: str = ""):
        tags = tags_custom if tags_custom else (
            "TAGS" in self.execution.local_parameters and self.execution.local_parameters['TAGS'])
        if not tags:
            return
        modified_nodegroup = Nodegroup.add_properties(
            "tags", tags, self.nodegroup)
        self.nodegroup = modified_nodegroup

    def __set_spot_properties__(self):
        spot_allocation_strategy = self.execution.local_parameters['ALLOCATION_STRATEGY']
        on_demand_base_capacity = self.execution.local_parameters['ON_DEMEND_BASE_CAPACITY']
        on_demand_percentage_above_base_capacity = self.execution.local_parameters[
            'ON_DEMEND_ABOVE_BASE_PERCENTAGE']
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
