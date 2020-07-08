from fennec_execution import Execution


class Namespace:
  def create(execution: Execution, name: str):
    if Namespace.check_if_exists(execution, name):
      print(f"namespace: {name} already exsits, skipping")
      return

  def delete(execution: Execution, name: str):
    if not Namespace.check_if_exists(execution, name):
      print(f"namespace: {name} doesn't exsit, skipping")
      return

  def check_if_exists(execution: Execution, name: str) -> bool:
    get_ns_command = "kubectl get namespaces -o json"
    namespaces_str = execution.run_command(get_ns_command)
    namespaces = Execution.json_to_object(namespaces_str.log)
    for namespace in namespaces['items']:
      if namespace['metadata']['name'] == name:
        return True
    return False
