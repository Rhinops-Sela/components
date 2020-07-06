import json
import os


class Execution:
    def __init__(self, working_folder: str):
        self.working_folder = working_folder
        self.__load_parameters__()
        self.debug = False if os.getenv('API_USER') else True

    def __load_parameters__(self):
        default_values_file = os.path.join(
            self.working_folder, "execution", "default.values.json")
        self.default_valuescd_file = default_values_file
        with open(default_values_file) as default_values:
            self.default_values = json.load(default_values)

    def get_local_parameter(self, parameter):
        return self.default_values['local'][parameter]

    def get_global_parameter(self):
        return self.default_values['global']


    def get_parameters(self):
        self.default_values = json.load(self.default_values_file)
