import os
from fennec_cluster.cluster import Cluster
cluster = Cluster(os.path.dirname(__file__))
cluster.delete()