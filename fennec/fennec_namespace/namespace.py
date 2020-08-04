from fennec_executers.kubectl_executer import Kubectl


class Namespace:

    def __init__(self, kubectl: Kubectl) -> None:
        self.kubectl = kubectl

    def create(self, name: str):
        if self.check_if_exists(name):
            print(f"namespace: {name} already exsits, skipping")
            return
        self.kubectl.create_namespace(name)

    def delete(self, name: str, force=True):
        if not self.check_if_exists(name):
            print(f"namespace: {name} doesn't exsit, skipping")
            return
        delete = force
        if not force:
            delete = self.verify_empty_before_delete(name)
        if delete:
            self.kubectl.delete_namespace(name)
        else:
            print(f"Namespace {name} contains resources, skipp deleting")

    def verify_empty_before_delete(self, name: str) -> bool:
        objects_in_namespace = self.kubectl.get_all(name)
        return True if not objects_in_namespace else False

    def check_if_exists(self, name: str) -> bool:
        namespaces = self.kubectl.get_object("namespace")
        for namespace in namespaces['items']:
            if namespace['metadata']['name'] == name:
                return True
        return False
