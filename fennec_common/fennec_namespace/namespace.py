from fennec_execution import Execution


class Namespace:
  def create(execution: Execution, name: str):
    if Namespace.check_if_exists(execution, name):
      print(f"namespace: {name} already exsits, skipping")
      return
    execution.run_command(f"kubectl create ns {name}")

  def delete(execution: Execution, name: str, force=True):
    if not Namespace.check_if_exists(execution, name):
      print(f"namespace: {name} doesn't exsit, skipping")
      return
    delete = force
    if not force:
      delete = Namespace.verify_empty_before_delete(execution, name)
    if delete:
      execution.run_command(f"kubectl delete ns {name}")
    else:
      print(f"Namespace {name} contains resources, skipp deleting")

  def verify_empty_before_delete(execution: Execution, name: str) -> bool:
    command = f"kubectl get all -n {name}"
    results = execution.run_command(command).log
    objects_in_namespace = Execution.json_to_object(results)
    return True if not objects_in_namespace else False

  def check_if_exists(execution: Execution, name: str) -> bool:
    get_ns_command = "kubectl get namespaces -o json"
    namespaces_str = execution.run_command(get_ns_command, show_output=False)
    namespaces = Execution.json_to_object(namespaces_str.log)
    for namespace in namespaces['items']:
      if namespace['metadata']['name'] == name:
        return True
    return False
