[![Build Status](https://dev.azure.com/Rhinops-Sela/k8s-bootstrapper/_apis/build/status/Rhinops-Sela.components?branchName=master)](https://dev.azure.com/Rhinops-Sela/k8s-bootstrapper/_build/latest?definitionId=7&branchName=master)

#note 
# components
### Component folder structure:
    .
    ├── Components
    │    ├── Component1                # Top level folder component folder
    │    │    ├── execution
    │    │    │   ├── nodegroup
    │    │    │   │   └── nodegroup.json    # eksctl nodegroup file
    │    │    │   ├── helm                  # helm values files
    │    │    │   │    ├── vlues.json
    │    │    │   │    ├── vlues1.json
    │    │    │   │    └── ...
    │    │    │   ├── page.json            # The UI representation of the component
    │    │    │   └── default.values.json  # Default values for user input
    │    │    │
    │    │    ├── create.py                # Executed during create phase
    │    │    └── delete.py                # Executed during delete phase
    │    ├── Component2                # Top level folder component folder
    │    ├── Component2                # Top level folder component folder
    │    └── ...
    └── form.json

### Example for nodegroup.json:
```json
{
  "apiVersion": "eksctl.io/v1alpha5",
  "kind": "ClusterConfig",
  "nodeGroups": [
    {
      "name": "fennec-ng",
      "minSize": 1,
      "maxSize": 200,
      "desiredCapacity": 1,
      "volumeSize": 100,
      "volumeType": "gp2",
      "privateNetworking": true,
      "iam": {
        "withAddonPolicies": {
          "autoScaler": true
        }
      }
    }
  ]
}
```
### Example for helm values.json:
```json
{
   "clusterName": "elasticsearch",
   "replicas": 1,
   "minimumMasterNodes": 1,
   "persistence": {
      "enabled": true,
      "annotations": {}
   },
   "nodeSelector": {
      "role": "elk"
   },
   "tolerations": [
      {
         "key": "elk",
         "operator": "Equal",
         "value": "true"
      }
   ]
}
```
### The UI Representation Of The Compoennt (page.json)
```json
{
  "name": "redis",
  "mandatory": true,
  "executer": "python3",
  "displayName": "Redis",
  "image": "assets/component_logos/redis.png",
  "description": "Redis configuration & parameters",
  "inputs": [
    {
      "template": "instance-select",
      "tooltip": "Selecte Redis cluster instance type",
      "options": [
        "m5.large",
        "m5.xlarge"
      ]
    },
    {
      "template": "spot",
      "group_enabler_master": "use_spot"
    },
    {
      "controlType": "text",
      "sub_group": "use_spot",
      "tooltip": "How many on demand instances will be created",
      "displayName": "# of On Demand Instances to Use",
      "serverValue": "ON_DEMEND_BASE_CAPACITY",
      "regexValidation": ".*"
    }
    {
      "controlType": "multi-select",
      "displayName": "Extra ARGS?",
      "options": [
        "--maxmemory-policy allkeys-lru"
      ],
      "serverValue": "EXTRA_FLAGS"
    },
    {
      "template": "dns-entry",
      "displayName": "Redis DNS Record",
      "serverValue": "REDIS_DNS_RECORD"
    }
  ]
}
```
<b>name</b> - compopnent's name, will be used internaly<br />
<b>mandatory</b> - If true the user must fill values in this page<br />
<b>executer</b> - the executer to use when running create/delete scripts<br />
<b>displayName</b> - The display text in the ui<br />
<b>description</b> - sub header will be displayed in the component's page<br />
<b>image</b> - the image which will be displayed in the UI<br />
<b>inputs</b> - all the user inputs to be displayed in the component's page<br />
<b>template</b>: will load a pre-defined input type from inputs folder
<br />i.e:
  ```json
    {
      "controlType": "multi-select",
      "displayName": "Instsance Type",
      "options": [
        "m5.xlarge",
        "m5.large",
        "m5.2xlarge"
      ],
      "regexValidation": ".*",
      "serverValue": "INSTANCE_TYPES"
    }
 ```

<b>controlType</b>: The control type to be displayed to the user, possible options:<br />
  * text
  * text-password
  * textarea
  * checkbox
  * select
  * multi-select

<br/><br/><b>displayName</b> - The display text in the ui<br />
<b>options</b> - List of possible options for the select control<br />
<b>regexValidation</b> - Regex expressions used to validate the user input if set this field will become mandatory.<br />
<b>serverValue</b> - This will be the variable name during create/delete execution<br />
<b>group_enabler_master</b> - The contorl type must be checkbox, when selected all inputs with sub_group property which have the same vlue will be added to the form when spot is checked ON_DEMEND_BASE_CAPACITY will be also displayed.<br />

** When using pre-defined inputs it's possible to overwrite their value's by adding the to the input object:
  ```json
    {
      "template": "dns-entry",
      "displayName": "Redis DNS Record",
      "serverValue": "REDIS_DNS_RECORD"
    }
 ```
 <pre>
 <b>displayName</b> will overwrite the original display name and the same applies for <b>serverValue</b>
</pre>
### Example for executoin default.values.json:
```json
{
   "local": [
     {
       "ON_DEMEND_BASE_CAPACITY": 5
     },
     {
       "REDIS_DNS_RECORD": "redis.fennec.io",
       "USE_AS_DEFAULT": true
     }
   ],
   "global": [
     {
       "CLUSTER_NAME": "fennec"
     },
     {
       "CLUSTER_REGION": "eu-west-2"
     },
     {
       "AWS_SECRET_ACCESS_KEY": "xxxxxxx"
     },
     {
       "AWS_ACCESS_KEY_ID": "xxxxxxxxxxx"
     }
   ]
}
```
<b>USE_AS_DEFAULT</b> - Even if no input recieved from user the variable will be set with it's deafult value.
## Global Page
```
Global page is a uniqe page, which allows to set global variables which will be avaliable for all pages in the installation.
```
```json
{
  "name": "global",
  "deletable": false,
  "mandatory": true,
  "displayName": "Global Parameters",
  "image": "assets/component_logos/aws.png",
  "description": "Global Parameters For The Deploymnet Process",
  "inputs": [
    {
      "controlType": "text",
      "tooltip": "AWS Access Key",
      "displayName": "Access Key",
      "regexValidation": ".*",
      "serverValue": "AWS_ACCESS_KEY_ID",
      "global": true
    },
    {
      "controlType": "text-password",
      "tooltip": "AWS Secret Access Key",
      "displayName": "Secret Access Key",
      "regexValidation": ".*",
      "serverValue": "AWS_SECRET_ACCESS_KEY",
      "global": true
    },
    {
      "controlType": "text",
      "serverValue": "CLUSTER_NAME",
      "regexValidation": ".*",
      "tooltip": "Will be used as the cluster name for enire installation",
      "displayName": "Cluster Name",
      "global": true
    },
    {
      "template": "region",
      "serverValue": "CLUSTER_REGION",
      "tooltip": "Will be used as the cluster region for enire installation",
      "displayName": "Cluster Region",
      "global": true
    }
  ]
}
```

## Create / Delete

<b>create.py / create.py (or eny other selected execution environement such as powershell or bash)</b> - files will be triggered during installation / deletion process accordingly.

```python
import os
#Execution requries current working directory as parameter
execution = Execution(os.getcwd(), "grafana")
# access the variables defined in the ui with a fallback to
#default variables values (when USE_AS_DEFAULT is set to ture)
masters = execution.local["NUMBER_OF_MASTER_NODES"]
cluster_name = execution.global["CLUSTRE_NAME"]

# template_path is optional, by default nodegroup.json  will be used
node_group = NodeGroup(cluster_name, template_path)
# add optional parameters according to user input
node_group.use_spot(0,0,"lowest-first")
#node_group.set_limits(min,max,desired)
node_group.set_limits(execution.local["MIN"], execution.local["MAX"], execution.local["DESIRED"])
#node_group.add_taints("fennec=true:NoSchedule")
node_group.add_taints(execution.local["TAINTS"])
#node_group.add_labels("role=fennec")
node_group.add_labels(execution.local["LABELS"])
#node_group.set_intances_types("t3.large,t2.large")
node_group.add_instances(execution.local["INSTANCES"])
#node_group.set_intances_types("arn****")
node_group.add_arns(execution.local["ARNS"])
#node_group.set_intances_types("eu-west-2")
node_group.region(execution.local["REGION"])
#Creates a new node group
node_group.create()
#Deletes node group
node_group.delete()

#if no namesapce was set localy use global namesapce
namespace = Namespace.Create(execution.local["${NAMESPACE}"] or execution.global["${NAMESPACE}"])

#load helm values file (use relative path from component's directory)
values1 = Execution.loadJson("execution/helm/values1.json")
#modify according to user inputs
values1.replicas = execution.local["REPLICAS"]
#Init Helm object
helm_chart = Helm(name = "redis", chart = "stable/redis", repoUrl = "https://kubernetes-charts.storage.googleapis.com")

#Install Helm Chart
helm_chart.install(values = values1, namespace = "redis")
#Install Helm Chart
helm_chart.delete(name = "redis", namespace = "redis")

#Add DNS record
DNS().create_record(source = execution.local("DNS_RECORD") , target = f"redis.{execution.local('NAMESPACE')}.svc.cluster.local")

#Delete DNS record
DNS().delete_record(source = execution.local("DNS_RECORD") , target = f"redis.{execution.local('NAMESPACE')}.svc.cluster.local")
```
## Form Page (form.json)

This object controls the grouping of pages in the ui component
```json
[
  {
    "name": "global",
    "displayName": "Global Parametes",
    "description": "Global Parametes which will be avaliabel as environment variabels during the deployment",
    "pages": [
      "global-parameters-page"
    ]
  },
  {
    "name": "cluster",
    "description": "EKS cluster configuration",
    "displayName": "Cluster",
    "pages": [
      "cluster-page",
      "nodegroup-page"
    ]
  },
  {
    "name": "monitoring",
    "description": "Configuration & Parameters for monitoring the cluster",
    "displayName": "Monitoring",
    "pages": [
      "grafana-page",
      "prometheus-page",
      "datadog-page"
    ]
  },
  {
    "name": "network",
    "description": "Networking configuration for the cluster",
    "displayName": "Networking",
    "pages": [
      "coredns-page",
      "openvpn-page",
      "nginx-page"
    ]
  },
  {
    "name": "databases",
    "displayName": "Databases",
    "description": "Selection of databases to available in the cluster",
    "pages": [
      "redis-page",
      "dynamo-page"
    ]
  },
  {
    "name": "elk",
    "displayName": "ELK",
    "description": "Selection of ELK components to be available in the cluster",
    "pages": [
      "elasticsearch-page",
      "kibana-page"
    ]
  }
]
```
