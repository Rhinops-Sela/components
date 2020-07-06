import os
from fennec_execution import *

# sets the working folder for the execution component
executoin = Execution(os.path.join(os.getcwd(), "grafana"))
print(executoin.get_local_parameter('ON_DEMAND_INSTANCES'))
print(executoin.get_global_parameter())
