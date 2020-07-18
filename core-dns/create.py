import os
from fennec_core_dns.core_dns import CoreDNS

core_dns = CoreDNS(os.path.join(os.getcwd(), "core-dns"))
core_dns.add_records()



