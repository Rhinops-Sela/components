import os
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.join(os.getcwd(), "nodegroup"))
template_path = os.path.join(
    execution.templates_folder, "general-ng-template.json")
nodegroup = Nodegroup(execution, execution.local_parameters["NAME"])
nodegroup.add_instance_types(execution.local_parameters['INSTANCE_TYPES'])
nodegroup.delete()                            
