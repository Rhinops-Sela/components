import json
import os
import sys
import subprocess
import shlex
from collections import namedtuple


class Execution:
    def __init__(self, working_folder: str):
        self.working_folder = working_folder
        self.execution_folder = os.path.join(self.working_folder, "execution")
        self.templates_folder = os.path.join(
            self.execution_folder, "templates")
        self.debug = False if os.getenv('API_USER') else True
        self.local_parameters = {}
        self.global_parameters = {}
        self.__load_parameters__()
        self.cluster_name = self.global_parameters["GLOBAL_CLUSTER_NAME"]
        self.cluster_region = self.global_parameters["GLOBAL_CLUSTER_REGION"]
        self.create_kubernetes_client()

    def __load_parameters__(self):
        default_values_file = os.path.join(
            self.execution_folder, "default.values.json")
        self.default_valuescd_file = default_values_file
        with open(default_values_file) as default_values:
            self.default_values = json.load(default_values)
            self.set_parameter('local', self.local_parameters)
            self.set_parameter('global', self.global_parameters)

    def set_parameter(self, kind: str, working_dictionary: dict):
        for parameter_name, parameter_value in self.default_values[kind].items():
            calculated_value = self.calculate_variable_value(
                parameter_name, parameter_value)
            working_dictionary[parameter_name] = calculated_value

    def create_kubernetes_client(self):
        if not self.debug:
            os.environ['AWS_ACCESS_KEY_ID'] = f'{self.global_parameters["GLOBAL_AWS_ACCESS_KEY_ID"]}'
            os.environ['AWS_SECRET_ACCESS_KEY'] = f'{self.global_parameters["GLOBAL_AWS_SECRET_ACCESS_KEY"]}'
        os.environ['AWS_DEFAULT_REGION'] = self.cluster_region
        self.kube_config_file = os.path.join(self.working_folder, '.kube')
        os.system(
            f'aws eks update-kubeconfig --name {self.cluster_name} --kubeconfig {self.kube_config_file}')

    def calculate_variable_value(self, parameter_name, parameter_value) -> str:
        if self.debug:
            return parameter_value['debug']
        if os.getenv(parameter_name):
            return os.getenv(parameter_name)
        if parameter_value['default']:
            return parameter_value['default']
        return ''

    def get_global_parameter(self):
        return self.default_values['global']

    def get_parameters(self):
        self.default_values = json.load(self.default_values_file)

    def run_command(self, command: str, show_output=True):
        output_str = ""
        command = command + f" --kubeconfig {self.kube_config_file}"
        process = subprocess.Popen(
            shlex.split(command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
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
        return command_result(rc, output_str)

    def exit(exit_code: int, message: str):
        print(message)
        sys.exit(exit_code)

    def json_to_object(string_to_convert: str):
        try:
            converted = json.loads(string_to_convert)
            return converted
        except:
            print("unable to parse output")

    def replace_in_file(source_file: str, output_file: str, strings_to_replace: dict, max=1):
        fin = open(source_file, "rt")
        fout = open(output_file, "wt")
        file_content = ""
        for line in fin:
            file_content += line
        for string_to_replace in strings_to_replace.keys():
            new_value = strings_to_replace[string_to_replace]
            file_content = file_content.replace(
                string_to_replace, new_value, max)
        fout.write(file_content)
        fin.close()
        fout.close()
        return file_content
