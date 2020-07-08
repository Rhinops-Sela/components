from fennec_execution import Execution


class Helm:
    def __init__(self, execution: Execution, chart_name: str, chart_tag: str, chart_url: str = "") -> None:
        self.execution = execution
        self.chart_name = chart_name
        self.chart_tag = chart_tag
        self.chart_url = chart_url

    def install_chart(self, namespace: str, values_files=[], set_values=[]):
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
        install_command = f"helm {verb} --wait --timeout 3600s {self.chart_name} {self.chart_tag} {self.combine_values_files(values_files)} -n {namespace} {self.combine_set_values(set_values)}"
        result = self.execution.run_command(install_command)

    def delete_chart(self, namespace: str):
        if self.check_if_chart_installed(namespace):
            print(
                f"chart: {self.chart_name} in namespace: {namespace} installed, uninstalling...")
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
            set_values_str = f"{set_values_str} --set {set_value}"
        return set_values_str

    def check_if_chart_installed(self, namespace: str) -> bool:
        command = "helm ls --all-namespaces -o json"
        installed_charts = self.execution.run_command(command).log
        for installed_chart in Execution.json_to_object(installed_charts):
            print(installed_chart)
