# Distributed Authentication Mesh {#sec:solution}

This section gives an overview and an in-depth documentation of the proposed solution. Furthermore, boundaries of the solution are provided along with common software engineering elements like requirements, non-functional requirements, an abstract and a conceptional architecture.

The proposed architecture provides a generic description for a solution to the described problem. For this project, a Proof of Concept (PoC) gives insights into the topic of manipulating HTTP requests in-flight. The PoC is implemented to run on a Kubernetes cluster to provide a practical example.

## Definition

A solution for the stated problems in {@sec:state_of_the_art} must be stateless and able to transform arbitrary credentials into a format that the target service understands. For this purpose, the architecture contains a service that runs as a sidecar among the target service. This sidecar intercepts requests to the target and transforms the Authorization HTTP header. The sidecar is used to intercept inbound and outbound traffic.

However, the solution **must not** interfere with the data flow itself. The problem of proxying data from point A to B is well solved. In the given work, an Envoy proxy delivers data between the services. Envoy allows the usage of an external service to modify requests in-flight.

## Goals and Non-Goals of the Project

This section presents the functional and non-functional requirements and goals for the solution. It is important to note that the implemented Proof of Concept (PoC) will not achieve all goals. Further work is needed to implement a solution according to the architecture that adheres to the stated requirements.

In {@tbl:functional-requirements}, we present the list of functional requirements or goals (REQ) for the proposed solution and the project in general.

```{.include}
tables/requirements.md
```

In {@tbl:non-functional-requirements}, we show the non-functional requirements or non-goals (NFR) for the proposed solution.

```{.include}
tables/non-functional-requirements.md
```

These goals and non-goals define the first list of REQ and NFR. During future work, this list may change to adjust to new challenges.

## Differentiation from Security Assertion Markup Language {#sec:saml}

The "Security Assertion Markup Language" (SAML) is a so-called "Federated Identity Management" (FIdM) standard. SAML, OAuth, and OIDC represent the three most popular FIdM standards. SAML is an XML framework for transmitting user data, such as authentication, entitlement, and other attributes, between services and organizations [@naik:SAMLandFIdM].

While SAML is a partial solution for the stated problem, it does not cover the use case when credentials need to be transformed to communicate with a legacy system. SAML enables services to share identities in a trustful way, but all communicating partners must implement the SAML protocol to be part of the network. This project addresses the specific transformation of credentials into a format for some legacy systems. The basic concept of SAML may be used as a baseline of security and the general idea of processing identities.

## Architecture of the Distributed Authentication Mesh

The following sections provide an architectural description of the proposed solution. First, a description gives an initial overview of the architecture and the conceptional idea. Afterward, an abstract architecture describes the concepts behind the distributed authentication mesh. Then the architecture is concretized with platform-specific examples based on Kubernetes.

The reader should note that the proposed architecture does not match the implementation of the PoC to the full extent. The goal of this project is to provide an abstract idea to implement such an authentication mesh, while the PoC proves the ability to modify HTTP requests in-flight.

### Federated Identity with Diverging Authentication Schemes

When a federated identity is used, a user is not required to present authentication credentials for each communication between services. At some point, the user validates his own identity and is authenticated in the application. This application can span over several services that share the same "trust". This does not contradict a zero-trust environment. A federated identity can be validated by each service and thus may be used in a zero-trust environment.

To achieve such a federated identity with diverging authentication schemes, the solution converts validated credentials (like access tokens) to a domain specific language (DSL). This format, in conjunction with a proof of the sender, validates the identity over the wire in the communication between services without the need of additional authentication. When all parties of a communication are trusted through verification, no information about the effective credentials leaks into the communication between services.

The concept of the distributed authentication mesh is to replace any user credentials from an outgoing HTTP request with the DSL representation of the user identity. On the receiving side, the DSL encoded identity in the incoming HTTP request is transformed to the valid user credentials for the target service.

Since the topic of the mesh is security, error handling is a delicate matter. The mesh does depend on existing infrastructure and principles. In the example of the PoC, that is implemented on Kubernetes, error handling relies on Kubernetes. The Operator injects the translators and proxies and Kubernetes is responsible for the operational state of those components. Thus, error handling is limited to the translator engine, which represents the critical element in the solution. When the translator encounters any error and the translator can not recover from the error, the request must be denied. The translator may crash, and it lies in the responsibility of Kubernetes to restart the translator.

### Conceptional Architecture {#sec:abstract_architecture}

This section describes the architecture of the proposed solution in an abstract and generalized way. As stated in the non-functional requirements, the concepts are not bound to any specific platform or a specific implementation nor required to run in a cloud environment. The concepts could be implemented as a "fat-client" solution for a Windows machine.

![Abstract Solution Architecture](diagrams/component/solution-architecture.puml){#fig:04_solution_architecture width=85%}

{@fig:04_solution_architecture} shows the abstract solution architecture. In the "support" package, generally available elements provide utility functions to the mesh. The solution requires a public key infrastructure (PKI) to deliver key material for signing and validation purposes. This key material may also be used to secure the communication between the nodes (or applications). Configuration and secret storage enable the applications to store and retrieve configurations and secret elements like passwords or key material.

Additionally, an optional automation component watches and manages applications. This component enhances the application services with the required components to participate in the distributed authentication mesh. Such a component is strongly suggested when the solution is used in a cloud environment to enable dynamic usage of the mesh. The automation injects the proxies, translators, and the required configurations for the managed components.

A (managed) application service consists of three parts. The source (or destination) service, which represents the deployed application itself, a translator that manages the transformation between the DSL of the identity and the implementation specific authentication format, and a proxy that manages the communication from and to the application.

The communication between instances in the authentication mesh is handled by the proxies. The mesh must not interfere with the data transmission, it is only responsible for modifying HTTP headers. Handling errors on the data plane is not part of the mesh and must be done by the implementation of the proxy.

### Platform-Specific Example in Kubernetes {#sec:specific_architecture}

For the following sections, the architecture shows elements of a Kubernetes cloud environment. The reason is to describe the specific architecture the context of the practice. {@tbl:kubernetes_terminology} explains used terms and concepts in Kubernetes which are used to describe the platform-specific architecture.

Since the example is Kubernetes specific, error handling and recovery mechanisms of Kubernetes can be used. So if a part of the mesh crashes due to an unexpected error, Kubernetes is responsible for restarting that part. Furthermore, Kubernetes is the orchestrator which takes actions to provide the running state of all applications. If any errors are encountered, proper logging must be provided.

#### Automation with an Operator

The automation part of the mesh is optional. When no automation is provided, the required proxy and translator elements must be started and maintained by some other means. However, in the context of Kubernetes, an Operator pattern enables an automated enhancement and management of applications.

![Automation with an Operator in a Kubernetes Environment](diagrams/component/automation-architecture.puml){#fig:automation_architecture width=70%}

The Operator (application lifecycle manager, see {@sec:definitions}) in {@fig:automation_architecture} watches the Kubernetes API for changes. When deployments or services are created, the Operator enhances the respective elements. "Enhancing" means that additional containers are injected into a deployment as sidecars. The additional containers contain the proxy and the translator. While the proxy manages incoming and outgoing communication, the translator manages the transformation of credentials from and to the DSL.

![The Operator determines the relevance of an object with this logic. If an object in Kubernetes is not a Deployment nor a Service, or does not contain specific "Labels", it is rejected.](diagrams/states/automation-is-relevant.puml){#fig:automation_relevant_parts short-caption="Determination of the Relevance of a Deployment or a Service" width=50%}

To determine if an object is relevant for the automation, the operator uses the logic shown in {@fig:automation_relevant_parts}. If the object in question is not a deployment (or any other deployable resource, like a "Stateful Set" or "Daemon Set") or a service, then it is not relevant for the mesh. If the object is not configured to be part of the mesh, then the automation ends here as well.

![Automated Enhancement of a Deployment and a Service. If the Operator decides that an object is relevant (see {@fig:automation_relevant_parts}), the object is enhanced depending on its type.](diagrams/sequences/automation-process.puml){#fig:automation_process short-caption="Automated Enhancement of a Deployment and a Service" width=70%}

The sequence that enhances deployments and services is shown in {@fig:automation_process}. The operator registers a "watcher" for deployments and services with the Kubernetes API. Whenever a deployment or a service is created or modified, the operator receives a notification. Then, the operator checks if the object in question "is relevant" by checking if it should be part of the authentication mesh. This participation can be configured — in the example of Kubernetes — via annotations, labels, or any other means of configuration. If the object is relevant, the operator injects sidecars into the deployment or reconfigures the service to use the injected proxy as the target for the network communication.

If the automation engine encounters errors, it relies on Kubernetes to perform actions to reach a meaningful state. Since the engine runs on Kubernetes, if any operational errors occur, the application is restarted by Kubernetes. Logging is essential to find such errors. If deployments and services cannot be modified, the operator shall try again in the next reconciliation cycle.

#### Public Key Infrastructure

The role of the public key infrastructure (PKI) in the solution is to act as the source for trust in the system. The PKI is responsible for generating and delivering key material to various components. As an example, a translator fetches a public/private key pair on startup and can sign the translated credentials with the key material. A receiver can then validate the signature and check the integrity of the transmitted data.

![The Relation of the Public Key Infrastructure and the System](diagrams/component/pki-architecture.puml){#fig:pki_architecture width=50%}

{@fig:pki_architecture} depicts the relation of the translators and the PKI. When a translator starts, it acquires trusted key material from the PKI (for example, with a certificate signing request). This key material provides the possibility to sign the identity that is transmitted to the receiving party. The receiving translator can validate the signature of the identity and the sending party. The proxies are responsible for the communication between the instances.

![Provide Key Material to the Translator](diagrams/sequences/pki-fetch-key-process.puml){#fig:pki_fetch_key_process width=65%}

The sequence in {@fig:pki_fetch_key_process} shows how the PKI is used by the translator to create key material for itself. When a translator starts, it checks if it already generated a private key and obtains the key (either by creating a new one or fetching the existing one). Then, a certificate signing request (CSR) is sent to the PKI. The PKI will then create a certificate with the CSR and return the signed certificate. The provided sequence shows one possible use case for the PKI. During future work, the PKI may also be used to secure communication between proxies with mTLS [@siriwardena:mTLS].

![Checking the Signature of the transmitted Identity](diagrams/sequences/pki-check-sign-process.puml){#fig:pki_check_signature width=70%}

When communication happens, as shown in {@fig:pki_check_signature}, the proxy forwards the HTTP headers that contain the transferred identity of the user in the DSL to the translator. In the case of a JWT token, the transformer may now confirm the signature of the JWT token with the obtained certificate since it is signed by the same Certificate Authority (CA). Then the transformation is performed and the proxy forwards the communication to the destination.

To increase the security and mitigate the problem of leaking certificates, it is advised to create short-living certificates in the PKI and refresh certificates periodically.

If the PKI encounters illegal signing requests, it must deny them. If any other unexpected errors happen, the application should log the error and then crashes to enable Kubernetes to restart the application again.

#### Networking with a Proxy

Networking in the proposed solution works with a combination of routing and communication proxying. The general purpose of the networking element is to manage data transport between instances of the authentication mesh and route the traffic to the source/destination.

![Networking with an Proxy](diagrams/component/networking-architecture.puml){#fig:networking_architecture width=75%}

As seen in {@fig:networking_architecture} the proxy is the mediator between source and destination of a communication. Additionally, he proxy manages the translation of the credentials by communicating with the translator to transform the identity of the authenticated user and transmit it to the destination where it gets transformed again. In addition, with the help of the PKI, the proxy can verify the identity of the sender via mTLS.

Since the authentication mesh relies on external software to take care of communication and networking, error handling is off-loaded to that specific software as well. The authentication mesh does not guarantee any connectivity between parts of the mesh. In the platform-specific example, if the configuration provided by the automation engine is faulty, Envoy will crash and log this matter to the standard output (i.e. the console). Any other errors encountered by Envoy result in their respective HTTP error messages.

##### Outbound Communication for an Application {.unnumbered}

![Outbound Networking Sequence](diagrams/sequences/networking-process-outbound.puml){#fig:outbound_networking_process width=60%}

In {@fig:outbound_networking_process} the outbound traffic flow is shown. The proxy is required to catch all outbound traffic from the source and performs the reversed process of {@fig:inbound_networking_process} by transforming the provided credentials from the source to generate the common format with the user identity. This identity is then inserted into the HTTP headers and sent to the destination. At the sink, the process of {@fig:inbound_networking_process} takes place — if the sink is part of the authentication mesh.

##### Inbound Accepted Communication for an Application {.unnumbered}

![Inbound Accepted Networking Sequence](diagrams/sequences/networking-process-inbound.puml){#fig:inbound_networking_process width=65%}

{@fig:inbound_networking_process} shows the general invocation during inbound request processing. When the proxy receives a request (in the stated example by the configured Kubernetes service), it calls the translator with the HTTP request detail. The PoC is implemented with an "Envoy" proxy. Envoy allows an external service to perform "external authorization"^[<https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter>] during which the external service may:

- Add new headers before reaching the destination
- Overwrite headers before reaching the destination
- Remove headers before reaching the destination
- Add new headers before returning the result to the caller
- Overwrite headers before returning the result to the caller

The translator uses this concept to consume a specific and well-known header to read the identity of the authorized user in the DSL. The identity is then validated and transformed to the authentication credentials needed by the destination. Then, the translator instructs Envoy to set the credentials for the upstream. In the PoC, this is achieved by setting the `Authorization` header to static Basic Authentication (RFC7617) credentials.

##### Inbound rejected Communication for an Application {.unnumbered}

If the incoming communication contains faulty, invalid, or no identification data, the proxy blocks the communication.

![Inbound Rejected Networking Sequence](diagrams/sequences/networking-process-inbound-rejected.puml){#fig:inbound_networking_process_rejected width=65%}

{@fig:inbound_networking_process_rejected} shows the sequence when no or invalid identity data is provided. The responses of the translator are defined in **RFC1945** and are the HTTP response status codes [@RFC1945]. The translator distinguishes two cases:

- No identity data
- Invalid identity data

If no identity data is present, the translator must return `HTTP 401 Unauthorized`, the error that is used when no authorization credentials are provided. When invalid authorization credentials are provided (a false or a modified identity), the translator must return `HTTP 403 Forbidden`, which is used when credentials are provided, but they are not valid [@RFC1945].

#### The Translation of Credentials to an Identity

The translator is responsible for transforming the identity from and to the domain-specific language (the common format). In conjunction with the PKI, the translator can verify the validity and integrity of the incoming identity.

![Translation of the transmitted user identity from the common format to the required format by the destination](diagrams/sequences/translator-process.puml){#fig:translator_process short-caption="Translator Process" width=65%}

When the translator receives a request to create the required credentials, it performs the sequence of actions as stated in {@fig:translator_process}. First, the proxy will forward the HTTP request data to the translator. Afterward, the translator checks if the transported identity is valid and signed by an authorized party in the authentication mesh. When the credentials are valid, they are translated according to the implementation of the translator. The proxy is then instructed with the actions to replace the transported identity with the correct credentials to access the destination.

The translator is the critical part of the authentication mesh. If it receives invalid credentials (e.g. an identity that has been tampered with, or just a wrong username/password combination), it must reject the request with a `HTTP 403 Forbidden` response. If no identity is provided at all, a `HTTP 401 Unauthorized` must be sent. When the translation engine encounters any unexpected error during translation of the identity (like not being able to access the secret storage, or failure of some database), it must reject the request. The translator must reject any request that cannot be transformed successfully. This error handling is used on the receiving and the sending side.

In the PoC, the proof of integrity is not implemented, but the transformation takes place, where a "Bearer Token"^[Access token of an IDP.] is used to check if the user may access the destination and then replaces the token with static Basic Authentication credentials.

## Securing the Communication between Applications

The communication between the proxies must be secured. Furthermore, the identity that is transformed over the wire must be tamper-proof. Two established formats would suffice, "SAML" and "JWT Tokens". While both provide the possibility to hash their contents and thus secure them against modification, in current OIDC environments, JWT tokens are already used as access and/or identity tokens. JWT provides a secure environment with public and private claim names [@RFC7519].

Other options to encode the identity are:

- Normal JSON
- YAML
- XML
- X509 Certificates
- Concise Binary Object Representation (CBOR) [@RFC8949]

The problem with other structured formats is that tamper protection and encoding must be implemented manually. JWT tokens provide a specified way of attaching a hashed version of the complete content and therefore provide a method of validating a JWT token if it is still pristine and if the sender is trusted [@RFC7519]. If the receiving end fetched the key material from the same PKI (and therefore the same CA), it can check the certificate and the integrity of the JWT token. If the signature is correct, the JWT token has been issued by a trusted and registered instance of the authentication network.

X509 certificates — as defined in **RFC5280** [@RFC5280] — introduce another valid way of transporting data and attributes to another party. "Certificate Extensions" can be defined by "private communities" and are attached to the certificate itself [@RFC5280].

While X509 certificates could be used instead of JWT to transport this data, using certificates would enforce the translator to act as intermediate CA and create new certificates for each request. From our experience, creating, extracting, and manipulating certificates, for example in C\#, is not a task done lightly. Since this solution should be as easy to use as it can be, manipulating certificates in translators do not seem to be a feasible option. For the sake of simplicity and well-known usage, further work on this project will probably use JWT tokens to transmit the identity data.

## Implementation Proof of Concept (PoC) {#sec:poc}

To prove that the general idea of the solution is possible, a PoC is implemented during the work of this project. The following technologies and environments build the foundation of the PoC:

- Environment: The PoC is implemented on a Kubernetes environment to enable automation and easy deployment for testing
- "Automation": A Kubernetes operator, written in .NET (C\#) with the "Dotnet Operator SDK"^[<https://github.com/buehler/dotnet-operator-sdk>]
- "Proxy": Envoy proxy which gets the required configuration injected as Kubernetes ConfigMap file
- "Translator": A .NET (F\#) application that uses the Envoy gRPC definitions to react to Envoy's requests and poses as the external service for the external authorization
- "Sample Application": A solution of three applications that pose as demo case with:
  - "Frontend": An ASP.NET static site application that authenticates itself against "ZITADEL"^[<https://zitadel.ch>]
  - "Modern Service": An ASP.NET API application that can verify an OIDC token from ZITADEL
  - "Legacy Service": A "legacy" ASP.NET API application that is only able to verify `Basic Auth` (RFC7617, see {@sec:basic_auth})

The PoC addresses the following questions:

- Is it possible to intercept HTTP requests to an arbitrary service
- Is it further possible to modify the HTTP headers of the request
- Can a sidecar service transform given credentials from one format to another
- Can a custom operator inject the following elements:
  - The correct configuration for Envoy to use external authentication
  - The translator module to transform the credentials

Based on the results of the PoC, the following further work may be possible:

- Specify the concrete format to transport identities
- Implement a secure way of transporting identities with validation of the integrity
- Provide production-ready versions for some translators and the operator
- Integrate the solution with a service mesh
- Further investigate the possibility of hardening the communication between services (e.g. with mTLS)

For the solution to be production-ready, at least the secure communication channel between elements of the mesh as well as the DSL for the identity must be implemented. To be of use in current cloud environments, an implementation in Kubernetes can provide insights on how to develop the solution for other orchestrators than Kubernetes.

When considering the abstract architecture in {@fig:04_solution_architecture}, the PoC on Kubernetes covers all elements but the PKI. The automation engine is implemented with a custom Operator as stated above. The proxy is a configured Envoy proxy configured by the Operator. The credential transformer is a custom software written in .NET (F\#). Config and Secret Storage are covered by Kubernetes itself with "ConfigMap" and "Secret" objects in Kubernetes.

### Case Study for the PoC

The demo application demonstrates the particular use case of the distributed authentication mesh. The application resides in an open-source repository on GitHub (<https://github.com/WirePact/poc-showcase-app>).

To install and run the case study without any interference of the Operator or the rest of the solution, follow the installation guide in the README on <https://github.com/WirePact/poc-showcase-app>. To install and use the whole PoC, following the instructions in Appendix B will install the operator and the case study.

When installed in a Kubernetes cluster, a user can open (depending on the local configuration) the URL to the frontend application^[In the example, it is "https://kubernetes.docker.internal" since this is the local configured default URL for "Docker Desktop"].

![Component Diagram of the Case Study](diagrams/component/showcase-app.puml){#fig:impl_components_showcase_app width=90%}

{@fig:impl_components_showcase_app} gives an overview of the components in the showcase application. The system contains an ASP.NET Razor Page^[<https://docs.microsoft.com/en-us/aspnet/core/razor-pages/>] application as the frontend, an ASP.NET API application with configured ZITADEL OIDC authentication as "modern" backend service, and another ASP.NET API application that only supports Basic Authentication as "legacy" backend. The frontend can only communicate with the modern API while the modern API can call an additional service on the legacy API.

![Sequence Diagram of the Communication in the Case Study](diagrams/sequences/showcase-app-calls.puml){#fig:seq_showcase_call width=75%}

In {@fig:seq_showcase_call}, we show the process of a user call in the demo application. The user opens the web application and authenticates himself with ZITADEL. After that, the user is presented with the application and can click the "Call API" button. The frontend application calls the modern backend API with the access token from ZITADEL and asks for customer and order data. The customer data is present on the modern API, therefore it is directly returned. To fetch the order data, the modern service relies on a legacy application which is only capable of Basic Authentication.

Depending on the configuration (i.e. the environment variable `USE_WIREPACT`), the modern service will call the legacy application with either transformed basic authentication credentials (when `USE_WIREPACT=false`) or with the ZITADEL access token (`USE_WIREPACT=true`). Either way, the legacy API receives basic authentication credentials in the form of `<username>:<password>` and returns the data.

### Automation Engine for Applications

As explained in {@sec:abstract_architecture}, the automation engine is generally optional. If omitted, the user is responsible for configuring the proxy and the translator. In the PoC, the automation engine is a Kubernetes Operator written with the .NET SDK in C\#. The source of the PoC Operator resides on GitHub: <https://github.com/WirePact/poc-operator>. The Operator (automated and customized management of resources in Kubernetes, see {@sec:kubernetes_operator}) intercepts events for `Deployments` and `Services`. To update services and deployments in the PoC, an annotation (key-value storage in the metadata of an object in Kubernetes) is used. In future work, the Operator may react to Custom Resource Definitions (CRD) as well.

![Activity Model for Kubernetes Resources in the Automation Engine](diagrams/states/operator-events.puml){#fig:poc_operator_events width=50%}

{@fig:poc_operator_events} gives an overview of the process that an event of the Kubernetes API completes. When the Operator receives a notification by Kubernetes that a service or a deployment was created or modified, the Operator determines the type and uses the specific controller to reconcile the resource. If the entity is a deployment/service and is relevant for the authentication mesh, the Operator will modify the deployment/service.

In the case of a deployment, the first step of the Operator is to determine if the entity is relevant for the authentication mesh with the concept in {@fig:automation_relevant_parts}. If the deployment contains the annotation `ch.wirepact/port` in its metadata, it is automatically part of the mesh. If the deployment is already configured, further reconfiguration is skipped. Otherwise, the Operator fetches the already configured ports of the deployment, and generates two additional ports. One port is used for the Envoy sidecar while the other is configured for the translator sidecar. The next step is to generate and store the Envoy configuration in a Kubernetes `ConfigMap`. Last, the sidecars are injected into the deployment configuration and the Kubernetes client stores the modified manifest.

When reconciling a service, the service counts as relevant if the annotation `ch.wirepact/deployment` is present in the metadata of the service. The value of this annotation stores the deployment object to which the service should point. The Operator reads the annotations on the service to determine the port in question and searches for the port in its manifest. The port will receive a new "target port" that points to the Envoy port of the deployment. Last, the Kubernetes client will store the changed service.

### Network and Routing Proxy for Communication

In the PoC, the proxy sidecar is an Envoy proxy with its configuration injected by the automation engine. The Operator injects the sidecar whenever a `Deployment` is created or updated via the Kubernetes API. A `ConfigMap` with the envoy configuration is created during reconciliation.

Two parts of the envoy configuration are crucial. First, the `filter_chain` of the inbound traffic listener contains a list of `http_filters`. Within this list of filters, the external authorization filter is added to force Envoy to check if a request is allowed or not:

```yaml
# ... more config
http_filters:
  - name: envoy.filters.http.ext_authz
    typed_config:
      '@type': type.googleapis.com/
        envoy.extensions.filters.http.
        ext_authz.v3.ExtAuthz
      transport_api_version: v3
      grpc_service:
        envoy_grpc:
          cluster_name: auth_translator
        timeout: 1s
      include_peer_certificate: true
  - name: envoy.filters.http.router
# ... more config
```

Second, via the configured name (`auth_translator`), the external authorization service must be added to the `clusters` list:

```yaml
# ... more config
- name: auth_translator
  connect_timeout: 0.25s
  type: STATIC
  typed_extension_protocol_options:
    envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
      '@type': type.googleapis.com/
        envoy.extensions.upstreams.http.
        v3.HttpProtocolOptions
      explicit_http_config:
        http2_protocol_options: {}
  load_assignment:
    cluster_name: auth_translator
    endpoints:
      - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: 127.0.0.1
                  port_value: <<PORT_VALUE>>
# ... more config
```

This configures Envoy to find the external authorization service on the local loopback IP on the configured port. Since the transformer uses gRPC (`grpc_service: envoy_grpc: ...` in the filter config), http2 must be enabled for the communication. In a productive environment, timeouts should be set accordingly.

### Translator {#sec:poc_translator}

The translator is the part of the PoC that performs the modification of HTTP headers per request. Since the intermediate DSL is not implemented in the PoC, the translator converts an access token to static basic authentication credentials. If any error occurs or the translator call exceeds ten seconds, Envoy returns a HTTP 403 Forbidden message by default. The source code is on GitHub: <https://github.com/WirePact/poc-demo-translator>.

![Communication with an Invalid Access Token](diagrams/sequences/translator-poc-process-403.puml){#fig:poc_translator_403 width=90%}

{@fig:poc_translator_403} shows the sequence for an access token that is not valid. Envoy forwards the HTTP headers to the translator that extracts the `Authorization` header. If it is not a `Bearer` access token, or if the validation with ZITADEL fails (if the token is invalid or has expired), the translator returns an `Unauthorized` (HTTP 401) or `Forbidden` (HTTP 403) response depending on the status. The `Unauthorized` status is returned when no access token is provided (i.e. the HTTP header is missing). `Forbidden` is used if the token is invalid. In either case, Envoy will return the returned status code to the caller and terminates the request. The destination application does not receive any communication or notification about this event.

![Communication with a Valid Access Token](diagrams/sequences/translator-poc-process-200.puml){#fig:poc_translator_200 width=90%}

In contrast to {@fig:poc_translator_403}, the sequence in {@fig:poc_translator_200} shows the success path of a communication. If the given access token is valid, the translator fetches the static Basic Authentication credentials (i.e. username and password) from the secret storage. The secret storage in the PoC is a simple Kubernetes Secret. The received credentials are then transformed in the correct encoded Basic Authentication format (as described in RFC7617). The translator returns an instruction set for Envoy to process the HTTP request. Envoy executes the instructions and forwards the call to the destination and returns the response — if any.

When the translator decides that the request is unauthorized or forbidden, it returns a `DeniedResponse` to Envoy. The response is encoded in a binary "Protocol Buffers"^[Binary Data Format by Google: <https://developers.google.com/protocol-buffers>].

In contrast to the rejected response, an accepting response may include modifications for HTTP headers. It is possible to add new, modify, and remove headers from the request for the upstream (i.e. the destination of the request), as well as adding additional or modifying headers for the downstream (i.e. the source of the request when the result is returned).
