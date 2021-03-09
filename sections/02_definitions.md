# Definitions and Boundaries

This section provides general information about the project,
the context and prerequisite knowledge.
It gives an overview of the context as well as terminology
and general definitions.

## Context

This project aims at the specific problem of declarative conversion
of credentials to ensure authorized communication between services.
The solution may be runnable on various platforms but will be implemented
according to Kubernetes standards. Kubernetes^[<https://kubernetes.io/>] is an
orchestration platform that works with containerized applications.
The solution introduces an operator pattern, as explained in
{@sec:kubernetes_operator}

The deliverables of this project may aid services to
communicate with each other despite different authentication
mechanisms. As an example, this could be used to enable a modern
web application that uses OpenID Connect (OIDC) as the authentication and authorization
mechanism to communicate with a legacy application that was deployed
on the Kubernetes cluster but not yet rewritten. This transformation of credentials
(from OIDC to Basic Auth) is done by the solution of this project instead
of manual work which may introduc code changes to either service.

To use the proposed solution of this project, no service mesh or other
complex layer is needed. The solution runs without those additional
parts on a Kubernetes cluster. To provide service discovery, the default
internal DNS capabilities of Kubernetes are sufficient.

## Kubernetes

### What is Kubernetes

Kubernetes is an open source platform that manages containerized
workloads and applications. Workloads may be accessed via "Services"
that use a DNS naming system. Kubernetes uses declarative definitions
to compare the actual state of the system with the expected state [@github:kubernetesWebsite].

![Container and Deployment Evolution. Description of the evolution of
deployments as found on the documentation website of Kubernetes [@github:kubernetesWebsite].
This image is licensed under the CC BY 4.0 license [@cc:CCBY4.0].
](images/Kubernetes/Container_Evolution.png){#fig:kubernetes_container_evolution
short-caption="Kubernetes Container Evolution"}

According to the Kubernetes team, the way of deploying applications
has evolved. As shown in {@fig:kubernetes_container_evolution}, the
"Traditional Era" was the time, when applications were deployed
via FTP access and started manually (e.g. on an Apache webserver).
Then the revolution to virtual machines came and technologies
that could virtualize a whole operating system, such
as VMWare, were born. The latest stage, "Container Era", defines
a new way deploying workloads by virtualizing processes instead of
operating systems and therefore better use the given resources
[@github:kubernetesWebsite].

Kubernetes is a major player in "Container Deployment" as seen in
{@fig:kubernetes_container_evolution} and supports teams with the following
features according to the documentation [@github:kubernetesWebsite]:

- **Service discovery and load balancing**: Use DNS names or IP addresses
  to route traffic to a container and if the traffic is high and multiple
  instances are available, Kubernetes does load balance the traffic
- **Storage orchestration**: Automatically provide storage in the form
  of mountable volumes
- **Automated rollouts and rollbacks**: When a new desired state is provided
  Kubernetes tries to achieve the state at a controlled rate and has the
  possibility of performing rollbacks
- **Automatec bin packing**: Kubernetes only needs to know how much
  CPU and RAM a workload needs and then takes care of placing
  the workload on a fitting node in the cluster
- **Self-healing**: If workloads are failing, Kubernetes tries to
  restart the applications and even kills services that do not
  respond to the configured health checks
- **Secret and configuration management**: Kubernetes has a store for
  sensitive data as well as configurational data that may change
  the behaviour of a workload

### Terminology

> TODO, make fancy (table is not nice)

Find the common Kubernetes terminology attached in {@tbl:kubernetes_terminology}.
The table provides a list of terms that will be used to explain concepts like
the operator pattern in {@sec:kubernetes_operator}.

| Object    | Description                                                                              |
| --------- | ---------------------------------------------------------------------------------------- |
| Container | Smallest possible unit in a deployment. Contains a workload and runs with a docker image |
| Pod       | Composed of multiple containers. Is ran by kubernetes as an "application" or "workload"  |

<!-- | Deployment | Defines a deployment that sp
ecifies the pod and how many replicas of the pod should run                       |
| Service    | Used to access a pod in
side Kubernetes (provides DNS name for a deployment)                                   |
| Watcher    | Open connection fro
m a Kubernetes client to the master API to g
et notified about changes to watched resources | -->

Table: Common Kubernetes Terminology {#tbl:kubernetes_terminology}

### Operator {#sec:kubernetes_operator}

An operator in Kubernetes is an extension
to the Kubernetes API itself. A custom operator typically manages
the whole lifecycle of an appliction it manages [@dobies:KubernetesOperators].
Such a custom operator can further be used to reconcile normal
Kubernetes resources or any combination thereof.

Some examples of application operators are:

- Prometheus Operator^[<https://github.com/prometheus-operator/prometheus-operator>]:
  Manages instances of Prometheus in a cluster
- Postgres Operator^[<https://github.com/zalando/postgres-operator>]:
  Manages PostgreSQL clusters inside Kubernetes, with the support
  of multiple instance database clusters

There exists a broad list of operators, which can be (partially)
viewed on [operatorhub.io](https://operatorhub.io/).

![Kubernetes Operator Workflow](diagrams/sequences/kubernetes-operator-process.puml){#fig:kubernetes_operator_workflow}

{@fig:kubernetes_operator_workflow} shows the general workflow of an event that
is managed by an operator. When an operator is installed and running on a
Kubernetes cluster, it registers "Resource Watchers" with the API and receives notifications
when the master node modifies resources a watched resource. The overviewed events
are "Added", "Modified" and "Deleted". There are two additional events that may
be returned by the API ("Error" and "Bookmark") but they are typically not needed
in an operator.

When the user interacts with the Kubernetes API (for example via the `kubectl` executable)
and creates a new instance of a resource, the API will first call any "Mutator" in a
serial manner. After the mutators, the API will call any "Validators" in parallel and
if no validator objects against the creation, the API will then store the resource and
tries to apply the transition for the new desired state. Now, the operator receives
the notification about the watched resource and may interact with the event. Such an
action may include to update resources, create more resources or even delete other instances.

### Service Mesh

briefly describe a service mesh.

## Authentication and Authorization

### Basic

### OpenID Connect (OIDC)

briefly describe OIDC
