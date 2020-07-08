from fennec_execution import Execution
from fennec_namespace.namespace import Namespace


class Helm:
    def __init__(self, execution: Execution, chart_name: str, chart_tag: str, chart_url: str = "") -> None:
        self.execution = execution
        self.chart_name = chart_name
        self.chart_tag = chart_tag
        self.chart_url = chart_url

    def install_chart(self, namespace: str, values_files=[], additional_values=[]):
        verb = "install"
        if self.check_if_chart_installed(namespace):
            print(
                f"chart: {self.chart_name} in namespace: {namespace} already installed, upgrading...")
            verb = "upgrade"
        else:
            print(
                f"chart: {self.chart_name} in namespace: {namespace} not installed, installing...")
        if self.chart_url:
            self.execution.run_command(
                f"helm repo add stable {self.chart_url}")
        self.execution.run_command("helm repo update")
        Namespace.create(self.execution, namespace)
        install_command = f"helm {verb} --wait --timeout 3600s {self.chart_name} {self.chart_tag} {self.combine_values_files(values_files)} -n {namespace} {self.combine_set_values(additional_values)}"
        self.execution.run_command(install_command)

    def delete_chart(self, namespace: str):
        if self.check_if_chart_installed(namespace):
            print(
                f"chart: {self.chart_name} in namespace: {namespace} installed, uninstalling...")
            uninstall_command = f"helm uninstall {self.chart_name} -n {namespace}"
            self.execution.run_command(uninstall_command)
            Namespace.delete(self.execution, namespace, force=False)
        else:
            print(
                f"chart: {self.chart_name} in namespace: {namespace} not installed, skipping...")

    def combine_values_files(self, values_files) -> str:
        values_files_str = ""
        for values_file in values_files:
            values_files_str = f"{values_files_str} --values {values_file}"
        return values_files_str

    def combine_set_values(self, set_values) -> str:
        set_values_str = ""
        for set_value in set_values:
            set_values_str = f"{set_values_str} {set_value}"
        return set_values_str

    def check_if_chart_installed(self, namespace: str) -> bool:
        command = "helm ls --all-namespaces -o json"
        installed_charts = self.execution.run_command(
            command, show_output=False).log
        for installed_chart in Execution.json_to_object(installed_charts):
            if installed_chart['name'] == self.chart_name and installed_chart['namespace'] == namespace:
                return True
        return False
