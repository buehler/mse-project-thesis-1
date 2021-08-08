+-----------+-----------------------------------------------------------+
|   Term    |                        Description                        |
+===========+===========================================================+
| Container | The smallest possible unit in a deployment.               |
|           | Contains the definition of the workload. A Pod contains   |
|           | one or more containers.                                   |
+-----------+-----------------------------------------------------------+
| Pod       | Composed of multiple containers.                          |
|           | Pod are the smalles deployable units in Kubernetes.       |
+-----------+-----------------------------------------------------------+
| Service   | A service enables (network) communication with one        |
|           | multiple pods.                                            |
+-----------+-----------------------------------------------------------+
| CRD       | A Custom Resource Definition (CRD) enables developers     |
|           | to extend the default Kubernetes API.                     |
+-----------+-----------------------------------------------------------+
| Operator  | An operator is a software that manages Kubernetes         |
|           | resources and their lifecycle. Operators may use CRDs     |
|           | to define custom objects on which they react when         |
|           | some event (`Added`, `Modified` or `Deleted`) triggers    |
|           | on a resource. For a more in-depth description, see       |
|           | {@sec:kubernetes_operator}.                               |
+-----------+-----------------------------------------------------------+

Table: Key Kubernetes Terminology {#tbl:kubernetes_terminology_small}
