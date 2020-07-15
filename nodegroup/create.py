import os
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.join(os.getcwd(), "nodegroup"))
template_path = os.path.join(
    execution.templates_folder, "general-ng-template.json")
nodegroup = Nodegroup(execution, execution.local_parameters["NAME"])


nodegroup.add_tags(execution.local_parameters['TAGS'])
nodegroup.add_instance_types(execution.local_parameters['INSTANCE_TYPES'])
nodegroup.add_labels(execution.local_parameters['LABELS'])
nodegroup.add_taints(execution.local_parameters['TAINTS'])
if execution.local_parameters['SPOT']:
    spot_allocation_strategy = execution.local_parameters['ALLOCATION_STRATEGY']
    on_demand_base_capacity = execution.local_parameters['ON_DEMEND_BASE_CAPACITY']
    on_demand_percentage_above_base_capacity = execution.local_parameters[
        'ON_DEMEND_ABOCE_BASE_PERCENTAGE']
    nodegroup.set_spot_properties(spot_allocation_strategy=spot_allocation_strategy, on_demand_base_capacity=on_demand_base_capacity,
                                  on_demand_percentage_above_base_capacity=on_demand_percentage_above_base_capacity)
nodegroup.create()                            
