import os
from fennec_cluster.cluster import Cluster
from fennec_execution import Execution

execution = Execution(os.path.join(os.getcwd(), "cluster"))
cluster = Cluster(execution)
cluster.delete()