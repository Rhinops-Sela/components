from pathlib import Path
import os
from fennec_executers.base_executer import BaseExecuter
from fennec_execution import Execution


class Kubectl(BaseExecuter):
    def __init__(self, execution: Execution) -> None:
        BaseExecuter.__init__(self, execution)

    def uninstall_folder(self, folder: str, namespace: str):
        self.__execute_folder(folder, namespace, False)

    def install_folder(self, folder: str, namespace: str):
        self.__execute_folder(folder, namespace, True)

    def install_file(self, file: str, namespace: str):
        self.__execute_file(file, namespace, 'install')
    
    def patch_file(self, content: str, namespace: str, entity_type: str):
         self.run_command(f"kubectl patch {entity_type} -n {namespace} --patch '{content}")

    def uninstall_file(self, file: str, namespace: str):
        self.__execute_file(file, namespace, 'delete')

    def __execute_file(self, file: str, namespace: str, verb: str):
        self.run_command(f"kubectl {verb} -f {file} -n {namespace}")

    def __execute_folder(self, folder: str, namespace: str, install: bool):
        files_execute = dict()
        verb = "apply" if install else "delete"
        for path in Path(folder).rglob('*.*'):
            original_name = path.name.replace('-execute', '')
            if not original_name in files_execute or '-execute' in path.name:
                files_execute[original_name] = os.path.join(folder, path.name)
        for file_to_execute in files_execute.keys():
            self.__execute_file(files_execute[file_to_execute], namespace, verb)

   
