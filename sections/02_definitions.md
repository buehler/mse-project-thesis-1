# Definitions and Clarification of the Scope {#sec:definitions}

This section provides general information about the project, the context, and prerequisite knowledge. It gives an overview of the context as well as terminology and general definitions.

## Scope of the Project

This project addresses the specific problem of declarative conversion of user credentials, for example an access token, to ensure authorized communication between services. When multiple services with different authentication mechanisms communicate with each other, the services need to translate the credentials and send them to their counterpart. The goal of this project is to prevent user credentials from being transmitted to other services and to remove the need for code changes to transform credentials to another format.

![Illustration of the problem with diverging authentication mechanisms](images/02/is_situation.png){#fig:02_def_is_situation width=85%}

{@fig:02_def_is_situation} shows an example where an automatic and dynamic translation of access credentials would be useful. Service A needs to translate the received OIDC access token to some information encoded in Basic Authentication to access Service B.

To solve the problem, an automation component enhances services that are part of the application with additional functionality. A proxy in front of the service captures in-, and outgoing traffic to modify the `Authorization` HTTP header. Additionally, a translator transforms the original authentication data into a form of identity and encodes it with a common language format. The receiving service can validate this encoded identity and transforms the identity into valid user credentials again. This automatic transformation of credentials (e.g. from OIDC to Basic Auth) replaces manual work which may introduce code changes to either service. The deliverables of this and further projects may aid applications or APIs to communicate with each other despite different authentication mechanisms.

The solution may be feasible for various platforms but to provide a practical demo application, the Proof of Concept (PoC) runs on Kubernetes. Kubernetes^[<https://kubernetes.io/>] is an orchestration platform that works with containerized applications. The PoC resides in an initial version in an open-source GitHub repository. The PoC demonstrates that it is possible to instruct an Envoy^[<https://www.envoyproxy.io/>] proxy to communicate with an injected service to modify authentication credentials in-flight. To separate the proposed solution from more complex concepts like a service mesh, the PoC can run without a service mesh on a Kubernetes cluster and uses the built-in service discovery of Kubernetes to communicate.

## Kubernetes as an Orchestration Engine

This section provides a general overview of Kubernetes. Kubernetes is a prominent orchestration engine that manages workloads on worker-nodes. In this project, Kubernetes is used as platform for the specific implementation example in the PoC. The solution does not require Kubernetes or any other cloud environment platform but certain features, like automation with operators, support the solution. It is possible to use other environments, such as Docker Swarm or a native implementation on an operating system, to run the proposed solution.

### Introduction

Kubernetes is an open-source platform that manages containerized workloads and applications. Workloads may be accessed via "Services" that use a DNS naming system. Kubernetes uses declarative definitions to compare the actual state of the system with the expected state [@github:kubernetesWebsite].

![Container and Deployment Evolution. Description of the evolution of deployments as found on the documentation website of Kubernetes [@github:kubernetesWebsite]. This image is licensed under the CC BY 4.0 license [@cc:CCBY4.0].](images/Kubernetes/Container_Evolution.png){#fig:kubernetes_container_evolution short-caption="Kubernetes Container Evolution"}

According to Kubernetes, the way of deploying applications has evolved. As shown in {@fig:kubernetes_container_evolution}, the "Traditional Era" was the time when applications were deployed via FTP access and started manually (e.g. on an Apache web server). Then the revolution to virtual machines came and technologies that could virtualize a whole operating system, such as VMWare, were born. The latest stage, "Container Era", defines a new way deploying workloads by virtualizing processes instead of operating systems and therefore better use the given resources [@github:kubernetesWebsite].

Kubernetes is a major player among others like "OpenShift" or "Cloud Foundry" in "Container Deployment" as seen in {@fig:kubernetes_container_evolution} and supports teams with the following features according to the documentation [@github:kubernetesWebsite]:

- **Service discovery and load balancing**: Use DNS names or IP addresses to route traffic to a container and if the traffic is high and multiple instances are available, Kubernetes does load balance the traffic
- **Storage orchestration**: Automatically provide storage in the form of mountable volumes
- **Automated rollouts and rollbacks**: When a new desired state is provided Kubernetes tries to achieve the state at a controlled rate and has the possibility of performing rollbacks
- **Automatic bin packing**: Kubernetes only needs to know how much CPU and RAM a workload needs and then takes care of placing the workload on a fitting node in the cluster
- **Self-healing**: If workloads are failing, Kubernetes tries to restart the applications and even kills services that do not respond to the configured health checks
- **Secret and configuration management**: Kubernetes has a store for sensitive data as well as configuration data that may change the behavior of a workload

The list of features is not complete. There are many concepts in Kubernetes that help to build complex deployment scenarios and enable teams to ship their applications in an agile manner.

Kubernetes works with containerized applications. In contrast to "plain" Docker, it orchestrates the applications and is responsible for the desired state depicted in the application manifest files. Examples of such deployments and other Kubernetes objects are available online in the documentation [@github:kubernetesWebsite]^[<https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment>].

### Terminology

In {@tbl:kubernetes_terminology_small}, we state the key terms for Kubernetes. A more complete list can be found in Appendix A in {@tbl:kubernetes_terminology}.

```{.include}
tables/kubernetes_terminology_small.md
```

![UML of Kubernetes Resources (partially)](diagrams/component/kubernetes-parts.puml){#fig:02_kubernetes_parts width=75%}

{@fig:02_kubernetes_parts} shows a partial part of Kubernetes objects. An operator can manage resources such as deployments or services. The operator may manage other resources or custom resources based on the configuration it uses. A deployment contains a pod, which contains containers. The container is the effective unit of work, defined by an image. The service allows communication with a specific container on a configured port.

## The Operator Pattern {#sec:kubernetes_operator}

An Operator can be seen as a software for Site Reliability Engineering (SRE). SRE is a set of patterns and principles that originated at Google to manage and run large applications and systems. An Operator can automatically manage a cluster of database servers or other complex applications that would require expert knowledge [@dobies:KubernetesOperators]. The term "Operator" may come from the fact, that it replaces an expert, for example a database admin, that would operate and manage the application manually.

An Operator in Kubernetes is an extension to the Kubernetes control plane and API itself. A custom Operator typically manages the whole lifecycle of an application it manages [@dobies:KubernetesOperators]. An Operator can further be used to reconcile normal Kubernetes resources or any combination thereof.

Some examples of application operators are:

- Prometheus Operator^[<https://github.com/prometheus-operator/prometheus-operator>]: Manages instances of Prometheus (open-source monitoring and alerting toolkit) in a cluster
- Postgres Operator^[<https://github.com/zalando/postgres-operator>]: Manages PostgreSQL clusters inside Kubernetes, with the support of multiple instance database clusters

There exists a broad list of operators, which can be (partially) viewed on [https://operatorhub.io](https://operatorhub.io/).

![Kubernetes Operator Workflow](diagrams/sequences/kubernetes-operator-process.puml){#fig:02_kubernetes_operator_workflow width=80%}

In {@fig:02_kubernetes_operator_workflow}, we depict the general workflow of an event that is managed by an operator. When an operator is installed and runs on a Kubernetes cluster, it registers "Resource Watchers" with the API and receives notifications if the master node modifies resources. The overviewed events are "Added", "Modified" and "Deleted". There are two additional events that may be returned by the API ("Error" and "Bookmark"), but they are typically not needed for reconciliation.

When the user interacts with the Kubernetes API (e.g. via the `kubectl` executable) and creates a new instance of a resource, the API will first call any "Mutator" in a serial manner. After the mutators, the API will call any "Validators" in parallel and if no validator objects against the creation, the API will then store the resource and tries to apply the transition for the new desired state. Now, the operator receives a notification about the watched resource and may interact with the event. Such action may include updating resources, create more resources or even delete other instances.

A theoretical example of the concept is an Operator that creates database users based on a custom resource definition. When a user creates a custom resource with a username and a password, the Operator reacts to the creation and calls for validators to check if the username is set and the password is set. If the validation passes, the mutator may change the username according to some rules (e.g. no uppercase letters) and then the API stores the custom resource. After the resource is stored, the Operator gets notified about the effective "creation" and can reconcile the resource accordingly.

## The Sidecar Pattern {#sec:kubernetes_sidecar}

According to Brendan Burns and David Oppenheimer, the sidecar pattern is the most common pattern for multi-container deployments [@burns:DesignPatternsForContainerSystems]. Sidecars are containers that enhance the functionality of the main container in a pod. An example for such a sidecar is a log collector, that fetches log files written to the file system and forwards them towards some log processing software [@burns:DesignPatternsForContainerSystems]. Another example is the Google CloudSQL Proxy^[<https://github.com/GoogleCloudPlatform/cloudsql-proxy>], which provides access to a CloudSQL instance from a pod without routing the whole traffic through Kubernetes services.

![Sidecar container extending a main container in a pod. As example, this could be a log collector [@burns:DesignPatternsForContainerSystems]. Both containers in the Pod share the same filesystem and can access files in the Pod. The Application writes logs into files and the Sidecar sends the logfiles into an S3 bucket.](images/02/sidecar_pattern.png){#fig:02_kubernetes_sidecar short-caption="Example of a Sidecar Container" width=45%}

The example shown in {@fig:02_kubernetes_sidecar} is extensible. Common use cases for sidecars include controlling the data flow in a cluster with a service mesh^[As done by Istio (<https://istio.io/latest/docs/reference/config/networking/sidecar/>)], providing access to secure locations^[Like the Google CloudSQL Proxy] or performing additional tasks such as collecting logs of an application. Since sidecars are tightly coupled to the original application, they scale with the pod. It is not possible to scale a sidecar without scaling the pod — and therefore the application — itself.

## Controlling the Data with a Service Mesh {#sec:service_mesh}

A "Service Mesh" is a dedicated infrastructure layer that handles intercommunication between services. It is responsible for the delivery of requests in a modern cloud application [@li:ServiceMesh]. An example is "Istio"^[<https://istio.io/>]. When using Istio, the applications do not need to know if there is a service mesh installed or not. Istio will inject a sidecar (see {@sec:kubernetes_sidecar}) into the deployments to handle the communication between services.

The service mesh provides a set of features [@li:ServiceMesh]:

- **Service discovery**: The mechanism to locate and communicate with a workload / service. In a cloud environment, the location of services will likely change, thus, the service mesh provides a way to access the services in the cloud.
- **Load balancing**: As an addition to the service discovery, the mesh provides load balancing mechanisms as is done by Kubernetes itself.
- **Fault tolerance**: The router in a service mesh is responsible to route traffic to healthy services. If a service is unavailable or even reports a crash, traffic should not be routed to this instance.
- **Traffic monitoring**: In contrast to the default Kubernetes possibilities, with a service mesh, the traffic from and to various services can be monitored in detail. This offers the opportunity to derive reports per target, success rates and other metrics.
- **Circuit breaking**: The ability to cut off an overloaded service and back off the remaining requests instead of totally failing the service under stress. A circuit breaker pattern measures the failure rate of a service and applies states to the service: "Closed" — requests are passed to the service, "Open" — requests are not passed to this instance, "Half-Open" — only a limited number is passed [@montesi:CircuitBreakers].
- **Authentication and access control**: Through the control plane, a service mesh may define the rules of communication. It defines which services can communicate with one another.

As observed in the list above, many of the features of a service mesh are already provided by Kubernetes. Service discovery, load balancing, fault tolerance and — though limited — traffic monitoring is already possible with Kubernetes. Introducing a service mesh into a cluster enables administrators to build more complex scenarios and deployments.

## Authentication, Authorization, and Security

This section provides an introduction to the used authentication mechanisms. The proposed solution is capable of handling more than the described schemes, but for the implementation of the PoC, Basic Authentication and OIDC were used.

### Basic Authentication (RFC7617) {#sec:basic_auth}

The `Basic` authentication is a trivial authentication scheme (i.e. a way to prove the identity of an entity) that accepts a username and a password encoded in Base64. To transmit the credentials, the username and the password are concatenated with a colon (`:`) and then encoded with Base64. The result is inserted into the HTTP request as the `Authorization` header with the prefix `Basic` [@RFC7617].

### OpenID Connect (OIDC) {#sec:auth_oidc}

OpenID Connect is not defined in an RFC. The specification is provided by the OpenID Foundation (OIDF). OIDC extends OAuth, which is defined by **RFC6749**.

OpenID Connect is an authentication scheme, that extends/complements the `OAuth 2.0` framework. OAuth itself is an authorization framework, that enables applications to gain access to a resource (API or other) [@RFC6749]. OAuth 2.0 only deals with authorization and grants access to data and features on a specific application. The OAuth framework by itself does not define _how_ the credentials are transmitted and exchanged [@RFC6749]. OIDC adds additional logic to OAuth 2.0 that defines _how_ these credentials must be exchanged. Thus, OIDC enables login and profile capabilities in any application that uses OIDC [@spec:OIDC].

![OIDC code authorization flow [@spec:OIDC]. Only contains the credential flow, without the explicit OAuth part. OAuth handles the authorization whereas OIDC handles the authentication.](diagrams/sequences/oidc-code-flow.puml){#fig:02_oidc_code_flow short-caption="OpenID Connect Code Flow" width=60%}

When a user wants to authenticate himself with OIDC, one of the possible "flows" is the "Authorization Code Flow". Other possible flows are the "Implicit Flow" and the "Hybrid Flow" [@spec:OIDC]. {@fig:02_oidc_code_flow} depicts the "Authorization Code Flow". A user that wants to access a certain resource (e.g. an API) on a relying party (i.e. something that relies on the information about the user) and is not authenticated and authorized, the relying party forwards the user to the identity provider (IdP). The user provides his credentials to the IdP and is returned to the relying party with an authorization code. The relying party can then exchange the authorization code for valid tokens on the token endpoint of the IdP. Typically, `access_token` and `id_token` are provided. While the `id_token` must be a JSON Web Token (JWT), the `access_token` can be in any format [@spec:OIDC].

An example of an `id_token` in JWT format may be:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
yJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.
flKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

The stated JWT token contains:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
{
  "sub": "1234567890",
  "name": "John Doe",
  "iat": 1516239022
}
```

Such JWT tokens contain information as well as a hash to secure integrity of the data. The mechanism of JWT tokens could be used to implement the "common language format" for the solution. It provides a mechanism to transmit data and protects the data against modification with a hash.

### Zero Trust Environment {#sec:zero-trust}

"Zero Trust" is a security model with a focus on protecting data and user credentials. The basic idea of zero trust is to assume that an attacker is always present. It does not matter if the application resides within an enterprise network, zero trust assumes that enterprise networks are no more trustworthy than any other public network. As a consequence of zero trust, applications are not implicitly trusted. Therefore, user credentials must be presented and validated for each access to a resource [@rose:zero-trust]. Zero trust can be summarized with: "Never trust, always verify".
