import os
from fennec_cluster.cluster import Cluster
from fennec_execution import Execution

cluster = Cluster(os.path.join(os.getcwd(), "cluster"))
cluster.delete()