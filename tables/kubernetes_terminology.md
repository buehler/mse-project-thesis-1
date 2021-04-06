+------------+------------------------------------------------------------+
|    Term    |                        Description                         |
+============+============================================================+
| Container  | Smallest possible unit in a deployment.                    |
|            | Contains the definition of the workload.                   |
|            | A container consists of a container image, arguments,      |
|            | volumes and other specific information to carry out        |
|            | a task.                                                    |
+------------+------------------------------------------------------------+
| Pod        | Composed of multiple containers. Is ran by kubernetes      |
|            | as an instance of a deployment. Pods may be scaled         |
|            | according to definitions or "pod scalers". Highly          |
|            | coupled tasks are deployed together in a pod               |
|            | (i.e. multiple coupled containers in a pod).               |
+------------+------------------------------------------------------------+
| Deployment | A deployment is a managed instance of a pod.               |
|            | Kubernetes will run the described pod with the             |
|            | desired replica count on the best possible worker          |
|            | node. Deployments may be scaled with auto-scaling          |
|            | mechanisms.                                                |
+------------+------------------------------------------------------------+
| Service    | A service enables communciation with one or                |
|            | multiple pods. The service contains a selector that        |
|            | points to a certain number of pods and then                |
|            | ensures that the pods are accessable via a DNS name.       |
|            | The name is typically a combination of the servicename and |
|            | the namespace (e.g. `my-service.namespace`).               |
+------------+------------------------------------------------------------+
| Resource   | A resource is something that can be managed by             |
|            | Kubernetes. It defines an API endpoint on the master       |
|            | node and allows Kubernetes to store a collection of        |
|            | such API objects. Examples are: `Deployment`, `Service`    |
|            | and `Pod`, to name a few of the built-in resources.        |
+------------+------------------------------------------------------------+
| CRD        | A Custom Resource Definition (CRD) enables developers      |
|            | to extend the default Kubernetes API. With a CRD,          |
|            | it is possible to create own resources which creates       |
|            | an API endpoint on the Kubernetes API. An example          |
|            | of such a CRD is the `Mapping` resource of                 |
|            | Ambassador^[<https://www.getambassador.io/>].              |
+------------+------------------------------------------------------------+
| Operator   | An operator is a software that manages Kubernetes          |
|            | resources and their lifecycle. Operators may use CRDs      |
|            | to define custom objects on which they react when          |
|            | some event (`Added`, `Modified` or `Deleted`) triggers     |
|            | on a resource. For a more in-depth description, see        |
|            | {@sec:kubernetes_operator}.                                |
+------------+------------------------------------------------------------+
| Watcher    | A watcher is a constant connection from a client           |
|            | to the Kubernetes API. The watcher defines some search     |
|            | and filter parameters and receives events for              |
|            | the found resources.                                       |
+------------+------------------------------------------------------------+
| Validator  | A validator is a service that may reject the creation,     |
|            | modification or deletion of resources.                     |
+------------+------------------------------------------------------------+
| Mutator    | Mutators are called before Kubernetes validates and stores |
|            | a resource. Mutators may return JSON patches               |
|            | [@bryan:JSONPatch] to instruct Kubernetes to modify        |
|            | a resource prior to validating and storing them.           |
+------------+------------------------------------------------------------+

Table: Common Kubernetes Terminology {#tbl:kubernetes_terminology}