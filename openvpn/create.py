import os
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

execution = Execution(os.path.join(os.getcwd(), "cluster"))
nodegroup = Nodegroup(execution)
nodegroup.add_taints()