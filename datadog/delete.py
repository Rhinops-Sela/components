import os
from fennec_executers.helm_executer import Helm
from fennec_execution.execution import Execution
from fennec_helpers.helper import Helper

working_folder = os.path.join(os.getcwd(), "datadog")
execution = Execution(working_folder)
datadog_chart = Helm(working_folder, "datadog")
datadog_chart.uninstall_chart()