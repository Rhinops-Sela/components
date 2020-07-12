import json
import os

class Execution:
    def __init__(self, working_folder: str):
        self.__kube_config_file = ""
        self.working_folder = working_folder
        self.local_parameters = {}
        self.default_values = ""
        self.global_parameters = {}
        self.__load_local_parameters__()
        self.__load_global_parameters__()
        self.set_aws_credentials()

    @property
    def output_folder(self):
        return os.getenv('OUTPUT_FOLDER') if os.getenv('OUTPUT_FOLDER') else os.path.join(self.working_folder, "..", "outputs")

    @property
    def debug(self):
        return False if os.getenv('API_USER') else True

    @property
    def execution_folder(self):
        return os.path.join(self.working_folder, "execution")

    @property
    def templates_folder(self):
        return os.path.join(self.execution_folder, "templates")

    @property
    def cluster_name(self):
        return self.global_parameters["GLOBAL_CLUSTER_NAME"]

    @property
    def cluster_region(self):
        return self.global_parameters["GLOBAL_CLUSTER_REGION"]

    @property
    def kube_config_file(self):
        if not self.__kube_config_file:
            self.create_kubernetes_client()
        return self.__kube_config_file

    def __load_parameters__(self, default_values_file, local=True):
        with open(default_values_file) as default_values:
            self.default_values = json.load(default_values)
            if local:
                self.set_parameter(self.local_parameters)
            else:
                self.set_parameter(self.global_parameters)

    def __load_local_parameters__(self):
        default_values_file = os.path.join(
            self.execution_folder, "default.values.json")
        self.__load_parameters__(default_values_file)

    def __load_global_parameters__(self):
        path = os.path.join(os.getcwd(),
                            "fennec", "fennec_global_parameters", "execution", "global.values.json")
        self.__load_parameters__(path, local=False)

    def set_parameter(self, working_dictionary: dict):
        for parameter_name, parameter_value in self.default_values.items():
            calculated_value = self.calculate_variable_value(
                parameter_name, parameter_value)
            working_dictionary[parameter_name] = calculated_value

    def set_aws_credentials(self):
        if not self.debug:
            os.environ['AWS_ACCESS_KEY_ID'] = f'{self.global_parameters["GLOBAL_AWS_ACCESS_KEY_ID"]}'
            os.environ['AWS_SECRET_ACCESS_KEY'] = f'{self.global_parameters["GLOBAL_AWS_SECRET_ACCESS_KEY"]}'
        os.environ['AWS_DEFAULT_REGION'] = self.cluster_region

    def create_kubernetes_client(self):
        self.__kube_config_file = os.path.join(self.working_folder, '.kube')
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

    # def get_parameters(self):
    #    self.default_values = json.load(self.default_values_file)

    