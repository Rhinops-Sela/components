import os
from fennec_execution import Execution

# sets the working folder for the execution component
execution = Execution(os.path.join(os.getcwd(), "grafana"))
print(execution.local_parameters['ON_DEMEND_BASE_CAPACITY'])
print(execution.global_parameters['GLOBAL_CLUSTER_NAME'])
