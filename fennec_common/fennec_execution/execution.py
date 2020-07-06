import json
import os


class Execution:
    def __init__(self, working_folder: str):
        self.working_folder = working_folder
        self.debug = False if os.getenv('API_USER') else True
        self.local_parameters = {}
        self.global_parameters = {}
        self.__load_parameters__()
        self.create_kubernetes_client()

    def __load_parameters__(self):
        default_values_file = os.path.join(
            self.working_folder, "execution", "default.values.json")
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
        os.environ['AWS_DEFAULT_REGION'] = "eu-west-2"
        self.kube_config_file = os.path.join(self.working_folder, '.kube')
        os.system(
            f'aws eks update-kubeconfig --name {self.global_parameters["GLOBAL_CLUSTER_NAME"]} --kubeconfig {self.kube_config_file}')

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
