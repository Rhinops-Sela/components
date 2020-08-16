import os
from fennec_executers.helm_executer import Helm

datadog_chart = Helm(os.path.dirname(__file__), "datadog")
datadog_chart.uninstall_chart()