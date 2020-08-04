import os
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper

working_folder = os.path.join(os.getcwd(), "datadog")
execution = Execution(working_folder)
datadog_chart = Helm(working_folder, "datadog")
values_file_path = os.path.join(
    execution.execution_folder, "values.json")
values_file_object = Helper.file_to_object(values_file_path)
values_file_object['datadog']['apiKey'] = execution.local_parameters['DD_API_KEY']
values_file_object['datadog']['appKey'] = execution.local_parameters['DD_APP_KEY']
execution_file = os.path.join(
    execution.working_folder, "datadog-execute.values.json")
Helper.to_json_file(values_file_object, execution_file)
datadog_chart.install_chart(release_name="stable",
                            additional_values=[f"--values {execution_file}"])
