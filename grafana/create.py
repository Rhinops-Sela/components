import os
from fennec_execution import *

# sets the working folder for the execution component
execution = Execution(os.path.join(os.getcwd(), "grafana"))
print(execution.local_parameters['ON_DEMAND_INSTANCES'])
print(execution.global_parameters['GLOBAL_CLUSTER_NAME'])
