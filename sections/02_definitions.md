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

The deliverables of this and further projects may aid services to
communicate with each other despite different authentication
mechanisms. As an example, this could be used to enable a modern
web application that uses OpenID Connect (OIDC) as the authentication and authorization
mechanism to communicate with a legacy application that was deployed
on the Kubernetes cluster but not yet rewritten. This transformation of credentials
(from OIDC to Basic Auth) is done by the solution of the projects instead
of manual work which may introduc code changes to either service.

This specific project provides a proof of concept (PoC) with an
initial version on a GitHub repository. The PoC demonstrates that
it is possible to instruct an Envoy^[<https://www.envoyproxy.io/>] proxy
to communicate with an injected service to modify authentication credentials
in-flight.

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

The list of features is not complete. There are many concepts in Kubernetes
which help to build complex deployment scenarios and enable teams
to ship their applications in an agile manner.

### Terminology

Find the common Kubernetes terminology attached in {@tbl:kubernetes_terminology}.
The table provides a list of terms that will be used to explain concepts like
the operator pattern in {@sec:kubernetes_operator}.

```{.include}
tables/kubernetes_terminology.md
```

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

### Sidecar {#sec:kubernetes_sidecar}

The sidecar pattern is the most common pattern for multi-container
deployments. Sidecars are containers that enhance the functionality
of the main container in a pod. An example for such a sidecar is
a log collector, that collects log files written to the file system
and forwards them towards some log processing software [@burns:DesignPatternsForContainerSystems, section 4.1].
Another example is the Google CloudSQL Proxy^[<https://github.com/GoogleCloudPlatform/cloudsql-proxy>],
which provides access to a CloudSQL instance from a pod without routing the whole traffic through
Kubernetes services.

![Sidecar container extending a main container
in a pod. As example, this could be a log collector
[@burns:DesignPatternsForContainerSystems, figure 1].](diagrams/component/sidecar-pattern.puml){#fig:kubernetes_sidecar
short-caption="Example of a sidecar container"}

The example shown in {@fig:kubernetes_sidecar} is extensible.
Such sidecars may be injected by a mutator or an operator to extend
functionality.

### Service Mesh {#sec:service_mesh}

A "Service Mesh" is a dedicated infrastructure layer that handles
intercommunication between services. It is responsible for the
delivery of requests in a modern cloud application [@li:ServiceMesh, section 2].
An example from the practice is "Istio"^[<https://istio.io/>]. When using
Istio, the applications do not need to know if there is a service mesh installed
or not. Istio will inject a sidecar (see {@sec:kubernetes_sidecar}) into
pods and handle the communication with the injected services.

The service mesh provides a set of features [@li:ServiceMesh, section 2]:

- **Service discovery**: The mechanism to locate and communicate
  with a workload / service. In a cloud environment, the location
  of services will likely change, thus the service mesh provides
  a way to access the services in the cloud.
- **Load balancing**: As an addition to the service discovery,
  the mesh provides load balancing mechanisms as is done by Kubernetes itself.
- **Fault tolerance**: The router in a service mesh is responsible
  to route traffic to healthy services. If a service is unavailable or
  even reports a crash, traffic should not be routed to this instance.
- **Traffic monitoring**: In contrast to the default Kubernetes possibilities,
  with a service mesh, the traffic from and to various services can be monitored
  in detail. This offers the opportunity to derive reports per target, success
  rates and other metrics.
- **Circuit breaking**: The ability to cut off an overloaded service and
  back off the remaining requests instead of totally failing the service under stress.
  A circuit breaker pattern measures the failure rate of a service and
  applies states to the service: "Closed" - requests are passed to the service,
  "Open" - requests are not passed to this instance, "Half-Open" - only a limited
  number is passed [@montesi:CircuitBreakers, section 2].
- **Authentication and access control**: Through the control plane,
  a service mesh may define the rules of communication. It defines which
  services can communicate with one another.

As observed in the list above, many of the features of a service mesh
are already provided by Kubernetes. Service discovery, load balancing,
fault tolerance and - though limited - traffic monitoring is already
possible with Kubernetes. Introducing a service mesh into a cluster
enables administrators to build more complex scenarios and deployments.

## Authentication and Authorization

### Basic {#sec:basic_auth}

The `Basic` authentication scheme is a trivial authentication that accepts
a username and a password encoded in Base64. To transmit the credentials,
a construct with the schematics of `<username>:<password>` is created and
inserted into the http request as the `Authorization` header with the prefix
`Basic` [@reschke:BasicAuth, section 2]. An example with the username
`ChristophBuehler` and password `SuperSecure` would result in the following header:
`Authorization: Basic Q2hyaXN0b3BoQnVlaGxlcjpTdXBlclNlY3VyZQ==`.

### OpenID Connect (OIDC) {#sec:auth_oidc}

OpenID Connect is an authenticating mechanism, that builds upon
the `OAuth 2.0` authorization protocol. OAuth 2.0 deals with authorization
only and grants access to data and features on a specific application.
OAuth by itself does not define _how_ the credentials are transmitted
and exchanged [@hardt:OAuth2.0Spec]. OIDC adds a layer on top of
OAuth 2.0 that defines _how_ these credentials must be exchanged. This
adds login and profile capabilities to any application that uses OIDC
[@sakimura:OIDCCore].

![OIDC code authorization flow [@sakimura:OIDCCore].
](diagrams/sequences/oidc-code-flow.puml){#fig:oidc_code_flow
short-caption="OIDC code flow"}

When a user wants to authenticate himself with OIDC, one of the possible
"flows" is the "Authorization Code Flow" [@sakimura:OIDCCore, sec. 3.1]. Other possible flows
are the "Implicit Flow" [@sakimura:OIDCCore, sec. 3.2] and the "Hybrid Flow"
[@sakimura:OIDCCore, sec. 3.3]. In {@fig:oidc_code_flow}, the "Authorization Code Flow" is
depicted. A user that wants to access a certain resource on a relying party (i.e. something
that relies on the information about the user) and is not authenticated and authorized, the
relying party forwards the user to the identity provider (IdP). The user provides his
credentials to the IdP and is returned to the relying party with an authorization code.
The relying party can then exchange the authorization code to valid tokens on the
token endpoint of the IdP. Typically, `access_token` and `id_token` are provided. While
the `id_token` must be a JSON Web Token (JWT) [@sakimura:OIDCCore, sec. 2],
the `access_token` can be in any format [@sakimura:OIDCCore, sec. 3.3.3.8].
