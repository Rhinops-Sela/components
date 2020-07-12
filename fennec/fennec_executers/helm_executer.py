from fennec_executers.base_executer import BaseExecuter
from fennec_execution import Execution
from fennec_helpers import Helper
from fennec_namespace.namespace import Namespace


class Helm(BaseExecuter):
    def __init__(self, execution: Execution, namespace: str, chart_name: str = "") -> None:
        BaseExecuter.__init__(self, execution)
        self.namespace = namespace
        self.chart_name = chart_name if chart_name else self.namespace

    @property
    def installed(self) -> bool:
        command = "helm ls --all-namespaces -o json"
        installed_charts = self.run_command(
            command, show_output=False).log
        for installed_chart in Helper.json_to_object(installed_charts):
            if installed_chart['name'] == self.chart_name and installed_chart['namespace'] == self.namespace:
                print(
                    f"chart: {self.chart_name} in namespace: {self.namespace} already installed, upgrading...")
                return True
        print(
            f"chart: {self.chart_name} in namespace: {self.namespace} not installed")
        return False

    def install(self, release_name: str, chart_url: str = "", additional_values=[]):
        verb = "upgrade" if self.installed else "install"
        if chart_url:
            self.run_command(
                f"helm repo add {release_name} {chart_url}")
        self.run_command("helm repo update")
        Namespace.create(self.execution, self.namespace)
        install_command = f"helm {verb} --wait --timeout 3600s {self.chart_name} {release_name}/{self.chart_name} -n {self.namespace} {self.combine_additoinal_values(additional_values)}"
        self.run_command(install_command)

    def uninstall(self):
        if self.installed:
            print("uninstalling...")
            uninstall_command = f"helm uninstall {self.chart_name} -n {self.namespace}"
            self.execution.run_command(uninstall_command)
            Namespace.delete(self.execution, self.namespace, force=False)
        else:
            print(f"skipping...")
