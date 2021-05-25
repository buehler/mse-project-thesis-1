# Distributed Authentication Mesh

This section gives a general overview of the proposed solution. Furthermore, boundaries of the solution are provided along with common software engineering elements like requirements, non-functional requirements, and the documentation of the architecture.

The proposed architecture provides a generic description for a solution to the described problem. For this project, a proof of concept (POC) gives insights into the general topic of manipulating HTTP requests in-flight. The POC is implemented to run on a Kubernetes cluster to provide a practical example.

## Definition

A solution for the stated problems in {@sec:deficiencies} must be able to transform arbitrary credentials into a format that the target service understands. For this purpose, the architecture contains a service that runs as a sidecar among the target service. This sidecar intercepts requests to the target and transforms the Authorization HTTP header. The sidecar is - like in a service mesh - used to intercept inbound and outbound traffic.

However, the solution **must not** interfere with the data flow itself. The problem of proxying data from point A to B is well solved. In the given work, an Envoy proxy is used to deliver data between the services. Envoy allows the usage of an external service to modify requests in-flight.

## Goals and Non-Goals of the Project

This section presents the functional and non-functional requirements and goals for the solution. It is important to note that the implemented proof of concept (POC) will not achieve all goals. Further work is needed to implement a solution according to the architecture that adheres to the stated requirements.

In {@tbl:functional-requirements}, we present the list of functional requirements or goals (REQ) for the proposed solution and the project in general.

```{.include}
tables/requirements.md
```

In {@tbl:non-functional-requirements}, we show the non-functional requirements or non-goals (NFR) for the proposed solution.

```{.include}
tables/non-functional-requirements.md
```

These goals and non-goals define the first list of REQ and NFR. During further work, this list may be changed to adjust to new challenges as the solution is implemented.

## Differentiation from other Technologies

To distinguish this project from other technologies, this section gives a differentiation to two specific topics. The given topics stand for a general architectural idea and the contrast to the presented solution.

### Security Assertion Markup Language

The "Security Assertion Markup Language" (SAML) is a so-called "Federated Identity Management" (FIdM) standard. SAML, OAuth, and OIDC represent the three most popular FIdm standards. SAML is an XML framework for transmitting user data, such as authentication, entitlement, and other attributes, between services and organizations [@naik:SAMLandFIdM].

While SAML is a partial solution for the stated problem, it does not cover the use case when credentials need to be transformed to communicate with a legacy system. SAML enables services to share identities in a trustful way, but all communicating partners must implement the SAML protocol to be part of the network. This project addresses the specific transformation of credentials into a format for some legacy systems. The basic idea of SAML may be used as a baseline of security and the general idea of processing identities.

### WS-\* {#sec:ws-deathstar}

The term "WS-\*" contains a broad class of specifications within the "Web Services Description Language" (WSDL) and "Simple Object Access Protocol" (SOAP) context. The specifications were created by the World Wide Web Consortium (W3C). However, the consortium never finished and released the specification.

SOAP is a protocol to exchange information between services in an XML encoded message. It provides a way of communication between web services. A SOAP message consists of an "envelope" that contains a "body" and an optional "header" to transfer encoded objects [@curbera:SOAP-and-WSDL]. An example SOAP message from @curbera:SOAP-and-WSDL:

```xml
POST /travelservice
SOAPAction: "http://www.acme-travel.com/checkin"
Content-Type: text/xml; charset="utf-8"
Content-Length: nnnn

<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP:Body>
    <et:eTicket xmlns:et="http://www.acme-travel.com/eticket/schema">
      <et:passengerName first="Joe" last="Smith"/>
      <et:flightInfo
        airlineName="AA"
        flightNumber="1111"
        departureDate="2002-01-01"
        departureTime="1905"/>
    </et:eTicket>
  </SOAP:Body>
</SOAP:Envelope>
```

WSDL is an XML-based description of a web service. The goal of WSDL is to provide a description of methods that may be called on a web service. WSDL fills the needed endpoint description that SOAP is missing. While SOAP provides basic communication, WSDL defines the exact methods that can be called on an endpoint [@curbera:SOAP-and-WSDL].

The distributed authentication mesh differs from WS-\* such that there is no exact specification required for the target service. While the solution contains a common domain language - a SOAP-like protocol to encode data - it does not specify the endpoints of a service. The solution merely interacts with the HTTP request that targets a specific service and transforms the credentials from the common format to the specific format. Of course, certain authentication schemes need additional information to generate their user credentials out of the data.

## Use Case of Dynamic Credential Transformation

The usefulness of such a solution shows when "older" or monolythic software moves to the cloud or when third party software is used that provides no accessable source code.

### Communicate with legacy software {.unlisted .unnumbered}

Precondition: Cloud Native Application (CNA) and legacy software are deployed with their respective manifests and the sidecars of the mesh are running.

1. The user is authenticated against the CNA
2. The user tries to access a resource on the legacy software
3. The CNA creates a request and "forwards" the credentials of the user
4. The proxy intercepts the request and forwards the credentials to the transformer
5. The transformer verifies the credentials and transforms them into a domain specific format
6. The proxy replaces the headers and forwards the request
7. The receiving proxy forwards the domain specific format to the translator of the target
8. The translator casts the credentials into the specific authentication scheme credentials
9. The receiving proxy forwards the request to the target service with the updated HTTP headers

Postcondition: The communication has taken place and no credentials have left the source service (the CNA). Furthermore, the legacy service does not know what specific authentication scheme was used by the source to identify the user.

This use case can be changed such that the receiving service is not a legacy software but some third party application where the source code is not accessable.

## Architecture of the Solution

The following sections provide an architectural overview over the proposed solution. The solution is initially described in prosa text. Afterwards, an abstract architecture describes the concepts behind the solution. Then the architecture is concretized with platform specific examples based on Kubernetes.

The reader should note, that the proposed architecture does not match the implementation of the POC to the full extent. The goal of this project is to provide an abstract idea to implement such a solution, while the POC proves the ability of modifying HTTP requests in-flight.

### Brief Description

In general, when some service wants to communicate with another service and the user does not need to authenticate himself, most likely a federated identity is in use. This means that at some point, the user validates his own identity and is then authenticated in the whole zone of trust. This does not contradict a zero trust environment. A federated identity can be validated by each service and thus may be used in a zero trust environment.

To achieve such a federated identity with diverging authentication schemes, the solution converts validated credentials to a domain specific language (DSL). This format, in conjunction with a proof of the sender, validates the identity over the wire in the communication between services without the need of additional authentication. When all parties of a communication are trusted through verification, no information about the effective credentials leak into the communication between services.

The basic idea of the distributed authentication mesh is to replace any user credentials from an outgoing HTTP request with the DSL representation of the users identity. On the receiving side, the DSL encoded identity in the incomming HTTP request is transformed to the valid user credentias for the target service.

### Abstract and Conceptional Architecture

This section describe the architecture of the proposed solution in an abstract and generalized way. The concepts are not bound to any specific platform or a specific implementation nor are they required to run in a cloud environment. The concepts could be implemented as "fat-client" solution for a Windows machine as well.

![Abstract Solution Architecture](diagrams/component/solution-architecture.puml){#fig:solution_architecture}

{@fig:solution_architecture} shows the abstract solution architecture. In the "support" package, general available elements provide utility functions to the mesh. The solution requires a public key infrastructure (PKI) to deliver key material for signing and validation purposes. This key material may also be used to secure the communication between the nodes (or applications). Furthermore a configuration and secret storage enables the applications to store and retrieve configurations and secret elements like credentials or key material.

Additionally, an optional automation component watches and manages application. This component enhances the application services with the required components to participate in the distributed authentication mesh. Such a component is strongly suggested when the solution is used on a cloud environment to enable a dynamic usage of the mesh. The automation injects the proxies, translators and the required configurations for the managed components.

A (managed) application service consists of three parts. First, the source (or destination) service, which represents the deployed application itself, a translator that manages the transformation between the DSL of the identity and the implementation specific authentication format and a proxy that manages the communication from and to the application.

### Platform-Specific Example in Kubernetes

For these sections, the architecture shows elements of a Kubernetes cloud environment. The reason is to describe the specific architecture in a practical way. However, the general idea of the solution may be deployed in various environments and is not bound to a cloud infrastructure. {@tbl:kubernetes_terminology} gives an overview of used terms and concepts in Kubernetes which are used to describe the platform-specific architecture.

#### Concrete Example of Communication

To give a concrete example of the solution, this section describes a situation, where the distributed authentication mesh helps to protect credentials and eases the process of translating credentials. The example can be used to comprehend the concepts of the solution.

The situation for the example is as follows:

- Two applications are deployed in a Kubernetes cluster
- Both applications are part of the authentication mesh
- The first application has an OIDC implementation that authenticates the user against an IDP
- The second application has a database with `userid`, `username`, and `password` combinations for authorized users
- The translator of the second application has access to the database
- JSON Web Tokens (JWT) are used as DSL to transform the identity

When the first application wants to communicate with the second application (on behalf of a user), the authentication mesh helps both systems to prevent the leakage of credentials and therefore sensitive information into the network.

The following steps describe the sequence of events during such a communication:

1. The first application wants to call the second application on behalf of user "Bob"
2. The outgoing communication is intercepted by the proxy and the transformer receives the HTTP headers of the call
3. The transformer checks if the access token is still valid (via IDP)
4. The transformer fetches the information about the owner (user) of this access token via IDP
5. The transformer creates a JWT token with the userid, username, firstname, lastname and other relevant information
6. The JWT token is signed with the private key of the transformer
7. The JWT token is returned to the proxy
8. The proxy removes the original credentials
9. The proxy attaches a well-known HTTP header for the authentication mesh that contains the JWT token
10. The request is sent by the proxy to the destination
11. The receiving proxy forwards the HTTP headers to the transformer on the receiving side
12. The transformer checks the integrity and validity of the JWT token
13. The transformer searches the database for userid "Bob"
14. The transformer constructs the required Basic Authentication credentials for user "Bob"
15. The transformer returns the credentials
16. The proxy removes the HTTP headers injected by the authentication mesh
17. The proxy attaches the authorization HTTP header with the received credentials
18. The proxy forwards the request to the destination application

> TODO: picture needed? this would be very big.

The given example enables two applications with different authentication mechanisms to communicate with each other without knowing the specifics about the authentication.

#### Automation with an Operator

In case of a Kubernetes infrastructure, the automation part is done by an operator pattern as explained in {@sec:kubernetes_operator}. The automation part of the mesh is optional. When no automation is provided, the required proxy and translator elements must be started and maintained by some other means. However, in the context of Kubernetes, an operator pattern enables an automated enhancement and management of applications.

![Automation with an Operator in a Kubernetes Environment](diagrams/component/automation-architecture.puml){#fig:automation_architecture}

The operator in {@fig:automation_architecture} watches the Kubernetes API for changes. When deployments or services are created, the operator enhances the respective elements. "Enhancing" means that additional pods are injected into a deployment as sidecars. The additional pods consist of the proxy and the translator. While the proxy manages incomming and outgoing communication, the translator manages the transformation of credentials from and to the DSL.

![Determination of the relevance of a Deployment or a Service](diagrams/states/automation-is-relevant.puml){#fig:automation_relevant_parts}

To determine if an object is relevant for the automation, the operator uses the logic shown in {@fig:automation_relevant_parts}. If the object in question is not a deployment (or any other deployable resource, like a "Stateful Set" or "Daemon Set") or a service, then it is not relevant for the mesh. If the object is not configured to be part of the mesh, then the automation ends here as well. The last step is to inject or reconfigure elements of the object depending on its effective type.

![Automated Enhancement of a Deployment and a Service](diagrams/sequences/automation-process.puml){#fig:automation_process}

The sequence that enhances deployments and services is shown in {@fig:automation_process}. The operator registers a "watcher" for deployments and services with the Kubernetes API. Whenever a deployment or a service is created or modified, the operator receives a notification. Then, the operator checks if the object in question "is relevant" by checking if it should be part of the authentication mesh. This participation can be configured - in the example of Kubernetes - via annotations, labels or any other means of configuration. If the object is relevant, depending on the type, the operator injects sidecars into the deployment or reconfigures the service to use the injected proxy as targeting port for the network communication.

#### Public Key Infrastructure

The role of the public key infrastructure (PKI) in the solution is to build the trust anchor in the system.

![The Relation of the Public Key Infrastructure and the System](diagrams/component/pki-architecture.puml){#fig:pki_architecture}

{@fig:pki_architecture} depicts the relation of the translators and the PKI. When a translator starts, it aquires trusted key material from the PKI (for example with a certificate signing request). This key material is then used to sign the identity that is transmitted to the receiving party. The receiving translator can validate the signature of the identity and the sending party. The proxies are responsible for the communication between the instances.

![Provide Key Material to the Translator](diagrams/sequences/pki-process.puml){#fig:pki_process}

The sequence in {@fig:pki_process} shows how the PKI is used by the translator to create key material for itself. When a translator starts, it checks if it already generated a private key and obtains the key (either by creating a new one or fetching the existing one). Then, a certificate signing request (CSR) is sent to the PKI. The PKI will then create a certificate with the CSR and return the signed certificate. The provided sequence shows one possible use case for the PKI. During future work, the PKI may also be used to secure communication between proxies with mTLS.

When communication happens, the proxy forwards the HTTP headers, that contain the transfered identity of the user in the DSL, to the translator. In case of a JWT token, the transformer may now confirm the signature of the JWT token with the obtained certificate since it is signed by the same Certificate Authority (CA). Then the transformation is performed and the proxy forwards the communication to the destination.

To increase the security and mitigate the problem of leaking certificates, it is adviced to create short living certificates in the PKI and refresh certificates periodically.

#### Networking with a Proxy

Networking in the proposed solution works with a combination of routing and communication proxing. The general purpose of the networking element is to manage data transport between instances of the authentication mesh and route the traffic to the source / destination.

![Networking with an Proxy](diagrams/component/networking-architecture.puml){#fig:networking_architecture}

As seen in {@fig:networking_architecture} the proxy is the mediator between source and destination of a communication. Furthermore, the proxy manages the translation of the credentials by communicating with the translator to transform the identity of the authenticated user and transmit it to the destination where it gets transformed again. Additionally, with the help of the PKI, the proxy can verify the identity of the sender via mTLS.

##### Inbound communication for an application

![Inbound Networking Process](diagrams/sequences/networking-process-inbound.puml){#fig:inbound_networking_process}

{@fig:inbound_networking_process} shows the general invocation during inbound request processing. When the proxy receives a request (in the given example by the configured Kubernetes service), it calls the translator with the HTTP request detail. The POC is implemented with an "Envoy" proxy. Envoy allows an external service to perform "external authorization"^[ <https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter>] during which the external service may:

- Add new headers before reaching the destination
- Overwrite headers before reaching the destination
- Remove headers before reaching the destination
- Add new headers before returning the result to the caller
- Overwrite headers before returning the result to the caller

The translator uses this concept to consume a specific and well-known header to read the identity of the authorized user in the DSL. The identity is then validated and transformed to the authentication credentials needed by the destination. Then, the translator instructs Envoy to set the credentials for the upstream. In the POC, this is done by setting the `Authorization` header to static Basic Authentication (RFC7617) credentials.

##### Outbound communication for an application

![Outbound Networking Process](diagrams/sequences/networking-process-outbound.puml){#fig:outbound_networking_process}

In {@fig:outbound_networking_process} the outbound traffic flow is shown. The proxy is required to catch all outbound traffic from the source and performs the reversed process of {@fig:inbound_networking_process} by transforming the provided information from the source to generate the common format with the users identity. This identity is then inserted into the HTTP headers and sent to the destination. At the sink, the process of {@fig:inbound_networking_process} takes place - if the sink is part of the authentication mesh.

#### The Translation of Credentials to an Identity

The translator is responsible for transforming the identity from and to the domain specific language. In conjunction with the PKI, the translator can verify the validity and integrity of the incomming identity.

![Translator Process](diagrams/sequences/translator-process.puml){#fig:translator_process}

When the translator receives a request to create the required credentials, it performs the sequence of actions as stated in {@fig:translator_process}. First, the proxy will forward the HTTP request data to the translator. Afterwards, the translator checks if the transported identity is valid and signed by an authorized party in the authentication mesh. When the credentials are valid, they are translated according to the implementation of the translator. The proxy is then instructed with the actions to replace the transported identity with the correct credentials to access the destination.

In the POC, the proof of integrity is not implemented, but the transformation takes place, where a "Bearer Token"^[access token of an IDP.] is used to check if the user may access the destination and then replaces the token with static Basic Authentication credentials.

## Securing the Communication between Applications

The communication between the proxies must be secured. Furthermore, the identity that is transformed over the wire must be tamper proof. Two established formats would suffice: "SAML" and "JWT Tokens". While both contain the possibility to hash their contents and thus secure them against modification, JWT tokens are better designed for HTTP headers, since in current OIDC environments, JWT tokens are already used as access and/or identity tokens. They provide a secure environment with public and private claim names [@RFC7519, sec. 4.2, sec. 4.3].

Other options to encode the identity could be:

- Simple JSON
- YAML
- XML
- X509 Certificates
- CBOR
- Any other structured format

The problem with other structured formats is that tamper protection and encoding must be done manually. JWT tokens provide a specified way of attaching a hashed version of the whole content and therefore provide a method of validating a JWT token if it is still valid and if the sender is trusted [@RFC7519]. If the receiving end has his key material from the same PKI (and therefore the same CA), it can check the certificate and the integrity of the JWT token. If the signature is correct, the JWT token has been issued by a trusted and registered instance of the authentication network.

X509 certificates - as defined in **RFC5280** [@RFC5280] - introduce another valid way of transporting data and attributes to another party. "Certificate Extensions" can be defined by "private communities" and are attached to the certificate itself [@RFC5280, sec. 4.2, sec. 4.2.2].

While X509 certificates could be used instead of JWT to transport this data, using certificates would enforce the translator to act as intermediate CA and create new certificates for each request. From our experience, creating, extracting and manipulating certificates, for example in C\#, is not a task done easily. Since this solution should be as easy to use as it can be, manipulating certificates in translators does not seem to be a feasible option. For the sake of simplicity and the well-known usage, further work to this project will probably use JWT tokens to transmit the users identity.

## Implementation Proof of Concept (POC)

To proof that the general idea of the solution is possible, a POC is implemented during the work of this project. The following technologies and environments build the foundation of the POC:

- Environment: The POC is implemented on a Kubernetes environment to enable automation and easy deployment for testing
- "Automation": A Kubernetes operator, written in .NET (C\#) with the "Dotnet Operator SDK"^[<https://github.com/buehler/dotnet-operator-sdk>]
- "Proxy": Envoy proxy which gets the required configuration injected as Kubernetes ConfigMap file
- "Translator": A .NET (F\#) application that uses the Envoy gRPC definitions to react to Envoy's requests and poses as the external service for the external authorization
- "Sample Application": A solution of three applications that pose as demo case with:
  - "Frontend": An ASP.NET static site application that authenticates itself against
    "ZITADEL"^[<https://zitadel.ch>]
  - "Modern Service": An ASP.NET API application that can verify an OIDC token from ZITADEL
  - "Legacy Service": A "legacy" ASP.NET API application that is only able to verify
    `Basic Auth` (RFC7617, see {@sec:basic_auth})

The POC addresses the following questions:

- Is it possible to intercept HTTP requests to an arbitrary service
- Is it further possible to modify the HTTP headers of the request
- Can a sidecar service transform given credentials from one format to another
- Can a custom operator inject the following elements:
  - The correct configuration for Envoy to use external authentication
  - The translator module to transform the credentials

Based on the results of the POC, the following further work may be realized:

- Specify the concrete format to transport identities
- Implement a secure way of transporting identities with validation of integrity
- Provide a production-ready solution for some translators and the operator
- Integrate the solution with a service mesh
- Provide a production-ready documentation of the solution
- Further investigate the possibility of hardening the communication between services (e.g. with mTLS)

For the solution to be production-ready, at least the secure communication channel between elements of the mesh as well as the DSL for the identity must be implemented. To be used in current cloud environments, an implementation in Kubernetes can provide insights on how to develop the solution for other orchestrators than Kubernetes.

### Case Study for the POC

The demo application shows the need and the particular use case of the distributed authentication mesh. The application resides in an open-source repository on GitHub (<https://github.com/WirePact/poc-showcase-app>).

When installed in a Kubernetes cluster, the user can open (depending on the local configuration) the URL to the frontend application^[In the example, it is "https://kubernetes.docker.internal" since this is the local configured URL for "Docker Desktop"].

![Component Diagram of the Case Study](diagrams/component/showcase-app.puml){#fig:impl_components_showcase_app}

{@fig:impl_components_showcase_app} gives an overview over the components in the showcase application. The system contains an ASP.NET Razor Page^[<https://docs.microsoft.com/en-us/aspnet/core/razor-pages/>] application as the frontend, an ASP.NET API application with configured ZITADEL OIDC authentication as "modern" backend service, and another ASP.NET API application that only supports Basic Authentication as "legacy" backend. The frontend can only communicate with the modern API and the modern API is able to call an additional service on the legacy API.

![Sequence Diagram of the Communication in the Case Study](diagrams/sequences/showcase-app-calls.puml){#fig:seq_showcase_call}

In {@fig:seq_showcase_call}, we show the process of a user call in the demo application. The user opens the web application and authenticates himself with ZITADEL. After that, the user is presented with the application and can click the "Call API" button. The frontend application calls the modern backend API with the access token from ZITADEL and asks for customer and order data. The customer data is present on the modern API so it is directly returned. To query the order data, the modern service relies on a legacy application which is only capable of Basic Authentication.

Depending on the configuration (i.e. the environment variable `USE_WIREPACT`), the modern service will call the legacy application with either transformed basic authentication credentials (when `USE_WIREPACT=false`) or with the presented access token (otherwise). Either way, the legacy API receives basic authentication credentials in the form of `<username>:<password>` and returns the data which then in turn is returned and presented to the user.

To install and run the case study without any interference of the operator or the rest of the solution, follow the installation guide in the readme on <https://github.com/WirePact/poc-showcase-app>. To install and use the whole POC, please refer to the installation guide in the Appendix.

### Automation Engine for Applications

As explained in the abstract section about the architecture, the automation engine is generally optional. If omitted, the user is responsible for configuring the proxy and the translator. In the POC, the automation engine is a Kubernetes operator written with the .NET SDK in C\#. The source of the POC operator is hosted on GitHub: <https://github.com/WirePact/poc-operator>. The operator (automated and customized management of resources in Kubernetes, see {@sec:kubernetes_operator}) intercepts events for `Deployments` and `Services`. To update services and deployments in the POC, an annotation (basically a key-value storage in the metadata of an object in Kubernetes) is used. In future work, the operator may react to Custom Resource Definitions (CRD) as well.

![Activity Model for Kubernetes Resources in the Automation Engine](diagrams/states/operator-events.puml){#fig:poc_operator_events}

{@fig:poc_operator_events} gives an overview of the process that an event of the Kubernetes API completes. When the operator is notified by Kubernetes that a service or a deployment was created or modified, the operator determines the type and uses the specific controller to reconcile the resource. If the entity is a deployment and it is relevant for the authentication mesh, the operator will modify the deployment. On the other hand, if the entity is a service, the operator modifies the service if it is part of the mesh.

![Automated Configuration of a Kubernetes Deployment in the POC](diagrams/states/operator-deployment.puml){#fig:poc_operator_deployment}

In the case of a deployment, {@fig:poc_operator_deployment} shows the process for the management-event of the deployment. The first step of the operator is to determine if the entity is relevant for the authentication mesh. If the deployment contains the annotation `ch.wirepact/port` in its metadata, it is automatically part of the mesh. If the deployment is already configured, further reconfiguration is skipped. If not, the operator fetches the already configured ports of the deployment, and generates two additional ports. One port is used for the Envoy sidecar while the other is configured for the translator sidecar. The next step is to generate and store the Envoy configuration in a Kubernetes `ConfigMap`. Last, the sidecars are injected into the deployment configuration and the Kubernetes client stores the modified manifest.

![Automated Configuration of a Kubernetes Service in the POC](diagrams/states/operator-service.puml){#fig:poc_operator_service}

When reconciling a service, {#fig:poc_operator_service} shows the activities of the operator during the reconciliation. The service counts as relevant, if the annotation `ch.wirepact/deployment` is attached in the metadata of the service. The value of this annotation gives the deployment object to which the service should point. Then, the operator reads the annotations on the service to determine the port in question and searches for the port in its manifest. Then the port will receive a new "target port", that points to the Envoy port of the deployment. Last, the Kubernetes client will store the changed service.

### Network and Routing Proxy for Communication

In the POC, the proxy sidecar is an Envoy proxy with its configuration injected by the automation engine. The operator injects the sidecar whenever a `Deployment` is created or updated via the Kubernetes API. The operator attaches the proxy and adds several annotations that are used for communication with a `Mutation Webhook`. Furthermore, a `ConfigMap` with the envoy configuration is created during the webhook.

Two parts of the envoy configuration are crucial. First, the `filter_chain` of the inbound traffic listener contains a list of `http_filters`. Within this list of filters, the external authorization filter is added to force Envoy to check if an arbitrary request is allowed or not:

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

Second, the external authorization service must be added to the `clusters` list to be access via the configured name (`auth_translator`):

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

This configures Envoy to find the external authorization service on the local loopback IP on the configured port. Since gRPC is configured (`grpc_service: envoy_grpc: ...` in the filter config), http2 must be enabled for the communication. In a productive environment, timeouts should be set accordingly.

### Translator

> TODO
