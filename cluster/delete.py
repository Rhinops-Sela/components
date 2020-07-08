# pip3 install -e /Users/iliagerman/Work/Sela/env_creator/components/fennec_common
import os
from fennec_cluster.cluster import Cluster
from fennec_core_dns.core_dns import CoreDNS
from fennec_execution import Execution
from fennec_helm.helm import Helm
from fennec_namespace import Namespace

execution = Execution(os.path.join(os.getcwd(), "cluster"))
cluster = Cluster(execution)
cluster.delete()