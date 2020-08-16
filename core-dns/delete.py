import os
from fennec_core_dns.core_dns import CoreDNS

core_dns = CoreDNS(os.path.dirname(__file__))
core_dns.delete_records(core_dns.execution.local_parameters["DNS_RECORDS"])



