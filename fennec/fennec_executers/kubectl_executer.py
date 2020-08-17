from pathlib import Path
import os
from fennec_execution import Execution
from fennec_helpers import Helper
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper


class Kubectl():
    def __init__(self, working_folder: str) -> None:
        self.execution = Execution(working_folder)

    def export_secret(self, secret_name: str, namespace: str, output_file_name: str):
        command = f'kubectl get secret -n {namespace} --kubeconfig {self.execution.kube_config_file} | grep "{secret_name}"'
        all_secrets_str = self.execution.run_command(
            command, show_output=False, kubeconfig=False).log.split("\n")
        for secret in all_secrets_str:
            if not secret.rstrip(' '):
                return
            secret_name = secret.split(' ')[0]
            secret_content = self.execution.run_command(
                f"kubectl get secret '{secret_name}' -o json -n {namespace}").log
            token = Helper.json_to_object(secret_content)[
                'data']['token']
            file_name = f'{output_file_name}.fennec_secret'
            self.execution.exeport_secret(file_name, token)
        else:
            print(f"Failed to export secret: {secret_name}")

    def combine_additoinal_values(self, set_values) -> str:
        set_values_str = ""
        for set_value in set_values:
            set_values_str = f"{set_values_str} {set_value}"
        return set_values_str

    def get_all(self, namespace: str, output="json"):
        command = f"kubectl get all -n {namespace}"
        result = self.execution.run_command(command).log
        return Helper.json_to_object(result) if output == "json" else result

    def get_object(self, object_kind: str, namespace: str = "all", output="json"):
        command = f"kubectl get {object_kind} -n {namespace}"
        if output == 'json':
            command += " -o json"
        result = self.execution.run_command(command, show_output=False).log
        return Helper.json_to_object(result) if output == "json" else result

    def uninstall_folder(self, folder: str, namespace: str):
        self.__execute_folder(folder, namespace, False)

    def install_folder(self, folder: str, namespace: str = ""):
        self.__execute_folder(folder, namespace, True)

    def install_file(self, file: str, namespace: str):
        self.__execute_file(file, namespace, 'apply')

    def patch_file(self, content: str, namespace: str, entity_type: str):
        self.execution.run_command(
            f"kubectl patch {entity_type} -n {namespace} --patch '{content}'")

    def uninstall_file(self, file: str, namespace: str):
        self.__execute_file(file, namespace, 'delete')

    def __execute_file(self, file: str, namespace: str, verb: str):
        command = f"kubectl {verb} -f {file} -n {namespace}" if namespace else f"kubectl {verb} -f {file}"
        self.execution.run_command(command)

    def __execute_folder(self, folder: str, namespace: str, install: bool):
        self.create_namespace(namespace)
        files_execute = dict()
        verb = "apply" if install else "delete"
        for path in Path(folder).rglob('*.*'):
            original_name = path.name.replace('-execute', '')
            if not original_name in files_execute or '-execute' in path.name:
                files_execute[original_name] = os.path.join(folder, path.name)
        for file_to_execute in files_execute.keys():
            self.__execute_file(
                files_execute[file_to_execute], namespace, verb)

    def create_namespace(self, name: str):
        if self.check_if_exists(name):
            print(f"namespace: {name} already exsits, skipping")
            return
        self.execution.run_command(f"kubectl create namespace {name}")

    def delete_namespace(self, name: str, force=True):
        if not self.check_if_exists(name):
            print(f"namespace: {name} doesn't exsit, skipping")
            return
        delete = force
        if not force:
            delete = self.verify_empty_before_delete(name)
        if delete:
            self.execution.run_command(f"kubectl delete namespace {name}")
        else:
            print(f"Namespace {name} contains resources, skipp deleting")

    def verify_empty_before_delete(self, name: str) -> bool:
        objects_in_namespace = self.get_all(name)
        return True if not objects_in_namespace else False

    def check_if_exists(self, name: str) -> bool:
        namespaces = self.execution.run_command("kubectl get namespace -n all").log
        for namespace in namespaces.split('\n'):
            if name in namespace:
                return True
        return False
    
    def get_ingress_address(self, ingress_name, namespace='all-namespaces'):
        command_result = self.execution.run_command(f"kubectl get ingress {ingress_name} -n {namespace} -o json").log
        ingress = Helper.json_to_object(command_result)
        ingress_address = ingress['status']['loadBalancer']['ingress'][0]['hostname']
        return ingress_address
