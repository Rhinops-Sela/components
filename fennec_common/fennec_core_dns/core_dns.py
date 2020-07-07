
from fennec_core_dns.dns_record import DNSRecord
from fennec_execution.execution import Execution
import os


class CoreDNS:
    def __init__(self, execution: Execution):
        self.execution = execution
        self.namespace = "kube-system"
        self.anchor_str = "        rewrite name fennec.ai fennec.ai"

    def add_records(self, dns_records):
        consfig_map = self.get_current_config()
        new_config = [str]
        for config_line in consfig_map.splitlines():
            if self.anchor_str in config_line:
                for dns_record in dns_records:
                    new_config.append(
                        f"        rewrite name {dns_record.source} {dns_record.target}")
                new_config.append(self.anchor_str)
            else:
                new_config.append(config_line)
        self.apply_changes(new_config)

    def delete_records(self, dns_records):
        consfig_map = self.get_current_config()
        new_config = [str]
        for dns_record in dns_records:
            for config_line in consfig_map.splitlines():
                if self.anchor_str in f"{dns_record.source} {dns_record.target}":
                    print(
                        f"deleting dns record: source: {dns_record.source} target: {dns_record.target}")
                else:
                    new_config.append(config_line)
        self.apply_changes(new_config)

    def reset(self, file_path: str):
        with open(file_path) as f:
            content = f.readlines()
        return self.apply_changes(content, False)

    def apply_changes(self, new_config, add_new_lines = True):
        output_file = os.path.join(self.execution.working_folder,
                                   "coredns-configmap-execute.yaml")
        outF = open(output_file, "w")
        for line in new_config:
            try:
                outF.write(line)
                if add_new_lines:
                    outF.write('\n')
            except:
                print("skipping line")
        outF.close()
        result = self.execution.run_command(
            f"kubectl apply -f {output_file} -n {self.namespace }")
        if(result.exit_code != 0):
            Execution.exit(result.exit_code, result.log)
        result = self.execution.run_command(
            f"kubectl delete pods -l k8s-app=kube-dns -n {self.namespace }")
        if(result.exit_code != 0):
            Execution.exit(result.exit_code, result.log)

    def get_current_config(self) -> str:
        command = f"kubectl get configmaps coredns -o yaml -n {self.namespace}"
        config_map = self.execution.run_command(command, show_output=False)
        if config_map.exit_code != 0:
            Execution.exit(exit_code=config_map.exit_code,
                           message=config_map.log)
        return config_map.log
