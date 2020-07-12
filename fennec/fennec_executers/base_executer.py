from abc import ABC, abstractmethod
from shlex import shlex
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper
import subprocess
from collections import namedtuple

from fennec_namespace import namespace

class BaseExecuter(ABC):
    
    @abstractmethod
    def __init__(self, execution:Execution) -> None:
        self.execution = execution

    def export_secret(self, secret_name: str, namespace: str):
        command = f'kubectl get secret -n {namespace} --kubeconfig {self.execution.kube_config_file} | grep "{secret_name}"'
        all_secrets_str = self.run_command(command, show_output=False, kubeconfig=False).log
        for secret in all_secrets_str: 
            print(secret)
        all_secrets = Helper.json_to_object(all_secrets_str)
        for secret in all_secrets:
            if secret_name == secret['metadata']['annotations']["kubernetes.io/service-account.name"]:
                print("found")
        else:
            return ""

    def combine_additoinal_values(self, set_values) -> str:
        set_values_str = ""
        for set_value in set_values:
            set_values_str = f"{set_values_str} {set_value}"
        return set_values_str


    def run_command(self, command: str, show_output=True, continue_on_error=False, kubeconfig=True):
        output_str = ""
        if kubeconfig:
            command = command + f" --kubeconfig {self.execution.kube_config_file}"
        process = subprocess.Popen(
            shlex(command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        while True:
            output = process.stdout.readline()
            poll = process.poll()
            if output:
                output_str = output_str + output.decode('utf8')
                if show_output:
                    print(output.decode('utf8'))
            if poll is not None:
                break
        command_result = namedtuple("output", ["exit_code", "log"])
        rc = process.poll()

        if rc != 0 and not continue_on_error:
            Helper.exit(rc, output_str)

        return command_result(rc, output_str)