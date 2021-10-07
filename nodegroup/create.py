import os
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution  = Execution(os.path.dirname(__file__))
template_path = os.path.join(execution.templates_folder, "generic-nodegrpup.json")
nodegroup = Nodegroup(os.path.dirname(__file__),template_path)
nodegroup.create()
