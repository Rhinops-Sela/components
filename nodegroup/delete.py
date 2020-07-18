import os
from fennec_execution.execution import Execution
from fennec_nodegorup.nodegroup import Nodegroup

nodegroup = Nodegroup(os.path.join(os.getcwd(), "nodegroup"))
nodegroup.delete()                            
