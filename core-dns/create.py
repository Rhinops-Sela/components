import os

from fennec_core_dns.core_dns import CoreDNS

core_dns = CoreDNS(os.path.join(os.getcwd(), "core-dns"))
core_dns.add_records(core_dns.execution.local_parameters["DNS_RECORDS"])



