# Distributed Authentication Mesh

This section gives a general overview of the proposed solution. Furthermore,
boundaries of the solution are provided along with common software engineering elements
like requirements, non-functional requirements and the documentation of the architecture.

The proposed architecture may be used as generic description for a solution to the
described problem. For this project, the solution is implemented specifically to work
within a Kubernetes cluster. The delivery of this project is a proof of concept
to provide insights into the general topic of manipulating HTTP requests in-flight.

## Definition

The solution to solve the stated problems in {@sec:deficiencies} must be able to
transform arbitrary credentials into a format that the target service understands.
For this purpose, the architecture contains a service which runs as a sidecar
among the target service. This sidecar intercepts requests to the target and
transforms the Authorization HTTP header. The sidecar is - like in a service mesh -
used to intercept inbound and outbound traffic.

However, the solution **must not**
interfere with the data flow itself. The problem of proxying data from point A to B
is a well solved problem. In the given work, an Envoy proxy is used to deliver data
between the services. Envoy allows the usage of an external service to modify
requests in-flight.

## Requirements

In {@tbl:functional-requirements}, we present the list of requirements (REQ)
for the proposed solution.

```{.include}
tables/requirements.md
```

It is important to note that the implemented proof of concept (PoC)
will not meet all requierements. Further work is needed to implement a solution
according to the architecture that adheres the stated requirements.

## Non-Functional Requirements

In {@tbl:non-functional-requirements}, we show the non-functional requirements (NFR)
for the proposed solution.

```{.include}
tables/non-functional-requirements.md
```

Like the requirements in {@tbl:functional-requirements}, the PoC will
not meet all NFRs that are stated in {@tbl:non-functional-requirements}. Further
work is needed to complete the PoC to a production ready software.

## Contrast

To distinguish this solution from other software, this sections gives
a contrast to two specific topics. The given topics stand for a general
architectural idea and the contrast to the presented solution.

### SAML

The "Security Assertion Markup Language" (SAML) is a so called "Federated Identity Management"
(FIdM) standard. SAML, OAuth and OIDC represent the three most popular FIdm standards
[@naik:SAMLandFIdM]. SAML is an XML framework for transmitting user data, such as
authentication, entitlement and other attributes, between services and organizations [@naik:SAMLandFIdM].

While SAML is a partial solution for the stated problem, it does not cover the use case
when credentials need to be transformed to communicate with a legacy system. SAML enables services
to share identities in a trustful way but all communicating partners must implement the SAML
protocol to be part of the network. This project addresses the specific transformation
of credentials into a format for some legacy systems. The basic idea of SAML however, may be used
as a baseline of security and the general idea of processing identities.

### WS-\* {#sec:ws-deathstar}

The term "WS-\*" contains a broad class of specifications within the WSDL/SOAP context.
The specifications were created by the World Wide Web Consortium (W3C) but never finished
and officially published.

The "Simple Object Access Protocol" (SOAP) is a protocol to
exchange information between services in an XML encoded message [@curbera:SOAP-and-WSDL].
It provides a way of communication between web services. A SOAP message consists of an "envelope" that
contains a "body" and an optional "header" to transfer encoded objects [@curbera:SOAP-and-WSDL].
An example SOAP message from @curbera:SOAP-and-WSDL looks like this:

```
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

The "Web Services Description Language" (WSDL), however, is an XML based description
of a web service. The goal of WSDL is to provide a description of methods that may be
called on a web service [@curbera:SOAP-and-WSDL].
WSDL fills the needed endpoint description that SOAP is missing. While SOAP provides
basic communication, WSDL defines the exact methods that can be called on
an endpoint [@curbera:SOAP-and-WSDL].

The proposed solution differs from WS-\* such that there is no exact specification
needed for the target service. While the solution contains a common domain language - a
SOAP like protocol to encode data - it does not specify the endpoints of a service.
The solution merely interacts with the HTTP request that targets a specific service
and transforms the credentials from the common format to the specific format.
Of course, certain authentication schemes need specific information to generate their
credentials out of the data.

## Architecture

The following sections provide an architectural overview over the proposed solution.
The solution is described in prosa text, as well as usual software engineering
diagrams with explanations. First, a description of the solution gives an introduction
about the idea, then the architecture shows the general overview of the solution
followed by sequence and communication definitions.

The reader should note, that the proposed architecture does not match the implementation
of the PoC to the full extent. The goal of this project is to provide a generalizable idea
to implement such a solution, while the PoC proves the ability of modifying HTTP requests
in-flight.

### Brief Description

In general, when some service wants to communicate with another service and the user does not
need to authenticate himself for every service, probably a federated identity is used. This means, that
at some point, the user validates his own identity and is then authenticated in the whole zone of
trust.

To achieve such a federated identity with diverging authentication schemes, the solution
converts validated credentials to a common language format. This format, in conjunction with
a proof of the sender, validates the identity over the wire in the communication between services
without the need of additional authentication. When all parties of a communication are trusted
through verification, no information about
the effective credentials leak into the communication between services.

The basic idea of the solution is to remove any credentials from an outgoing HTTP request with
the common format of the users identity and replace the common format in the ingoing HTTP
request into the valid credentials of the given scheme.

### Use Case

The usefulness of such a solution shows when "older" or monolythic software moves to the cloud
or when third party software is used that provides no accessable source code.

**Communicate with legacy software**

Precondition: Cloud native application and legacy software are deployed with
their respective manifests and the sidecars are running.

1. The user is authenticated against the CNA
2. The user tries to access a resource on the legacy software
3. The CNA creates a request and "forwards" the credentials of the user
4. The proxy intercepts the request and forwards the credentials to the transformer
5. The transformer verifies the credentials and transforms them into a common format
6. The proxy replaces the headers and forwards the request
7. The receiving proxy forwards the common format to the translator of the target
8. The translator casts the credentials into the specific authentication scheme credentials
9. The receiving proxy forwards the request with the updated HTTP headers

Postcondition: The communication has taken place and no credentials have left the source
service (CNA). Furthermore, the legacy service does not know what credentials or what specific
authentication scheme was used.

This use case can be changed such that the receiving service is not a legacy software but
an old and non-maintained application that is deployed into a cloud environment without refactoring.
Another possibility could be some third party application where the source code is not
accessable.

### Solution Architecture

In this section, we describe the system architecture of the proposed solution.
The architecture is shown in a diagram and then broken down to the individual parts.

![Solution Architecture](diagrams/component/solution-architecture.puml){#fig:solution_architecture}

{@fig:solution_architecture} shows the general solution architecture. In the "support" package,
general available elements are presented. The solution needs a public key infrastructure (PKI)
to deliver key material for signing and validation purposes. Furthermore a configuration and
secret storage must be provided.

Additionally, an optional automation component watches and manages applications. In case of
cloud environments, this component is strongly suggested to automate deployment configuration.
The automation does inject the proxies, translators and the specific needed configurations for
the managed components.

An application service consists of three parts. First, the source (or destination) service, which
represents the deployed application itself, a translator that manages the transformation between
the common language format of the identity and the implementation specific authentication format
and a proxy that manages the communication from and to the application.

For the further sections, the architecture shows elements of a Kubernetes cloud environment.
The reason is to describe the specific architecture in a practical way. However, the general
idea of the solution may be deployed in various environments and is not bound to a cloud
infrastructure.

#### Automation

In case of a Kubernetes infrastructure, the automation part is done by an operator as
explained in {@sec:kubernetes_operator}.

![Automation Architecture](diagrams/component/automation-architecture.puml){#fig:automation_architecture}

The operator in {@fig:automation_architecture} watches the Kubernetes API for changes. When
deployments or services are created, the operator enhances the respective elements. "Enhancing"
in this context means, that additional pods (see {@tbl:kubernetes_terminology})
are injected into a deployment as sidecars. The additional sidecars are the proxy and
the translator. While the proxy manages incomming ("ingress") and outgoing ("egress")
communication, the translator manages the transformation of credentials from and to a common
format.

![Automation Process](diagrams/sequences/automation-process.puml){#fig:automation_process}

The process that enhances deployments is shown in {@fig:automation_process}. The operator
registers a "watcher" for deployments and services with the Kubernetes API. Whenever
a deployment or a service is created or modified, the operator receives a notification.
Then, the operator checks of the object in question "is relevant" by checking if it
is part of the authentication mesh. This participation can be configured - in the example
of Kubernetes - via annotations, labels or any other means of configuration.
If the object is relevant, depending on the type, the operator injects sidecars
into the deployment or reconfigures the service to use the proxy as targeting
port for the service communication.

#### Public Key Infrastructure (PKI)

The role of the public key infrastructure in the solution is to build the trust anchor in
the system.

![PKI Architecture](diagrams/component/pki-architecture.puml){#fig:pki_architecture}

{@fig:pki_architecture} depicts the relation of the translators and the PKI.
When a translator starts, it aquires trusted key material from the PKI (for example with
a certificate signing request). This key material is then used to sign the identity
that is transmitted to the receiving party. The receiving translator can validate the
signature of the identity and the sending party. The proxies are responsible for the
communication between the instances.

![PKI Process](diagrams/sequences/pki-process.puml){#fig:pki_process}

The sequence in {@fig:pki_process} shows how the PKI is used by the translator
to create key material for itself. When a translator starts, it checks if it
already generated a private key and obtains the key (either by creating a new one
or fetching the existing one). Then, a certificate signing request (CSR) is sent
to the PKI. The PKI will then create a certificate with the CSR and return
the signed certificate.

When communication happens, the proxy will forward the HTTP headers of the
request to the translator which contains the transfered identity of the
user in the DSL. In case of a JWT token, the transformer may now confirm
the signature of the JWT token with the obtained certificate since it is signed
by the same Certificate Authority (CA). Then the transformation may happen and
the proxy forwards the communication to the destination.

To increase the security and mitigate the problem of leaking certificates,
it is adviced to create short living certificates in the PKI and resign certificates
periodically.

#### Networking

Networking in the proposed solution works with a combination of routing and
communication proxing. The general purpose of the networking element is to manage
data transport between instances of the authentication mesh and route the traffic to
the source / destination.

![Networking Architecture](diagrams/component/networking-architecture.puml){#fig:networking_architecture}

As seen in {@fig:networking_architecture} the proxy is the
mediator between source and destination of a communication.
Furthermore, the proxy manages the translation by communicating with the translator
to transform the identity of the authenticated user and transmit it to the destination
where it gets transformed again.
Additionally, with the aid of the PKI, the proxy can verify the identity of the sender via mTLS.

##### Ingress

![Inbound Networking Process](diagrams/sequences/networking-process-inbound.puml){#fig:inbound_networking_process}

{@fig:inbound_networking_process} shows the general process during inbound request processing.
When the proxy receives a request (in the given example by the configured Kubernetes service),
it calls the translator with the HTTP request detail. The PoC is implemented with the "Envoy" proxy.
Envoy allows an external service to perform "external authorization"^[
<https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter>]
during which the external service may:

- Add new headers before reaching the destination
- Overwrite headers before reaching the destination
- Remove headers before reaching the destination
- Add new headers before returning the result to the caller
- Overwrite headers before returning the result to the caller

The translator uses this concept to consume a specific and well-known header to read
the identity of the authorized user in the common format. The identity is then validated
and transformed to the authentication credentials needed by the destination. Then, the
translator instructs Envoy to set the credentials for the upstream. In the PoC, this
is done by setting the `Authorization` header to static Basic Auth credentials.

##### Egress

![Outbound Networking Process](diagrams/sequences/networking-process-outbound.puml){#fig:outbound_networking_process}

In {@fig:outbound_networking_process} the outbound (egress) traffic is described.
The proxy needs to catch all traffic from the source and performs the reversed process
(of {@fig:inbound_networking_process}) by transforming the provided
information from the source to generate the common format with the users identity.
This identity is then inserted into the HTTP headers and sent to the destination.
At the sink, the process of {@fig:inbound_networking_process} takes place - if the
sink is part of the authentication mesh.

#### Translator

The translator is responsible for transforming the identity from and to the common domain
specific language.

![Translator Architecture](diagrams/component/translator-architecture.puml){#fig:translator_architecture}

In conjunction with the PKI, the translator can verify the validity and integrity
of the incomming identity.

![Translator Process](diagrams/sequences/translator-process.puml){#fig:translator_process}

When the translator receives a request to create the needed credentials, it performs
the sequence of actions as stated in {@fig:translator_process}. First, the proxy
will forward the needed data to the translator. Afterwards, the translator will check if the
transported identity is valid and signed by an authorized party in the authentication mesh.
When the credentials are valid, they are translated according to the implementation of the
translator. The proxy is then instructed with the actions to replace the transported
identity with the correct credentials to access the destination.

In the PoC, the proof of integrity is not implemented, but the transformation takes
place, where a "Bearer Token"^[Opaque OIDC Token of an IDP.] is used to check if the user
may access and then replaces the token with static Basic Auth credentials.

### Communication

The communication between the proxies must be secured. Furthermore, the identity that
is transformed over the wire must be tamper proof. Two established formats would suffice:
"SAML" and "JWT Tokens". While both contain the possibility to hash their contents and
thus secure them against modification, JWT tokens are better designed for HTTP headers,
since in current OIDC environments, JWT tokens are already used as access and/or identity tokens.
They provide a secure environment with public and private claim names [@RFC7519, sec. 4.2, sec. 4.3].

Other options could be:

- Simple JSON
- YAML
- XML
- X509 Certificates
- Any other structured format

The problem with other structured formats is that tamper protection and encoding must be done manually.
JWT tokens provide a specified way of attaching a hashed version of the whole
content [@RFC7519] and therefore provide a method of validating a JWT token if it is
still valid and if the sender is trusted. If the receiving end has his key material
from the same PKI (and therefore the same CA), it can check the certificate
and the integrity of the JWT token. If the signature is correct, the JWT
token has been issued by a trusted and registered instance of the authentication network.

X509 certificates - as defined in **RFC5280** [@RFC5280] - define another valid way
of transporting data and properties about something to another party.
"Certificate Extensions" can be defined by "private communities" and
are attached to the certificate itself [@RFC5280, sec. 4.2, sec. 4.2.2].

While X509 certificates could be used instead of JWT to transport this data,
using certificates would enforce the translator to act as intermediate CA
and create new certificates for each request.
From our experience, creating, extracting and manipulating certificates, for example in C\#,
is not a task done easily. Since this solution should be as easy to use as it can be,
manipulating certificates in translators does not seem to be a feasible option.
For the sake of simplicity and the well known usage, further work to this project
will probably use JWT tokens to transmit the users identity.

## Implementation Proof of Concept (PoC)

To provide a proof that the general idea of the solution is possible,
a PoC is implemented during the work of this project.
The solution is implemented with the following technologies and environments:

- Environment: The PoC is implemented on a Kubernetes environment to
  enable automation and easy deployment for testing
- "Automation": A Kubernetes operator, written in .NET (F\#) with the
  "Dotnet Operator SDK"^[<https://github.com/buehler/dotnet-operator-sdk>]
- "Proxy": Envoy proxy which gets the needed configuration
  injected as Kubernetes ConfigMap file
- "Translator": A .NET (F\#) application that uses the Envoy gRPC defintions
  to react to Envoy's requests and poses as the external service for the
  external authorization
- "Showcase App": A solution of three applications that pose as demo case with:
  - "Frontend": An ASP.NET static site application that authenticates itself against
    "Zitadel"^[<https://zitadel.ch>]
  - "Modern Service": A modern ASP.NET api application that can verify an OIDC token from Zitadel
  - "Legacy Service": A "legacy" ASP.NET api application that is only able to verify
    `Basic Auth` (RFC7617, see {@sec:basic_auth})

The PoC addresses the following questions:

- Is it possible intercept HTTP requests to an arbitrary service
- Is it further possible to modify the HTTP headers of the request
- Can a sidecar service transform given credentials from one format to another
- Can a custom operator inject the following elements:
  - The correct configuration for Envoy to use external authentication
  - The translator module to transform the credentials

Based on the results of the PoC, the following further work may be realized:

- Specify the concrete common domain language to transport identities
- Implement a secure way of transporting identities with validation of integrity
- Provide a production ready solution of some translators and the operator
- Integrate the solution with a service mesh
- Provide a production ready documentation of the solution
- Further investiage the possibility of hardening the communication between services
  (e.g. with mTLS)

For the solution to be production ready, at least the secure communication channel
between elements of the mesh as well as the common language format must be implemented.
To be used in current cloud environments, an implementation in Kubernetes can provide
insights on how to develop the solution for other orchestrators than Kubernetes.

### Showcase Application

The showcase application is a demo to show the need and the particular
usecase of the solution. The application resides in an open source repository
under <https://github.com/WirePact/poc-showcase-app>.

When installed in a Kubernetes cluster,
the user can open (depending on the local configuration) the URL to the frontend
application^[In the example it is https://kubernetes.docker.internal since
this is the local configured URL for "Docker Desktop"].

![Component Diagram of the Showcase Application
](diagrams/component/showcase-app.puml){#fig:impl_components_showcase_app}

{@fig:impl_components_showcase_app} gives an overview over the components
in the showcase application. The system contains an ASP.NET Razor Page^[
<https://docs.microsoft.com/en-us/aspnet/core/razor-pages/>]
application as the frontend, an ASP.NET API application with
configured Zitadel OIDC authentication as "modern" backend
service and another ASP.NET API application that only supports basic authentication
as "legacy" backend. The frontend can only communicate with the modern API and
the modern API is able to call an additional service on the legacy API.

![Sequence Diagram of the Showcase Call
](diagrams/sequences/showcase-app-calls.puml){#fig:seq_showcase_call}

In {@fig:seq_showcase_call}, we show the process of a user call in the showcase
application. The user opens the web application and authenticates himself
with Zitadel. After that, the user is presented with the application and can click
the "Call API" button. The frontend application will call the modern backend API
with the OIDC token and asks for customer and order data. The customer data is present
on the modern API so it is directly returned. To query order data, the modern service
relies on a legacy application which is only capable of basic authentication.

Depending on the configuration (i.e. the environment variable `USE_WIREPACT`),
the modern service will call the legacy one with either transformed basic auth
credentials (when `USE_WIREPACT=false`) or with the presented OIDC token (otherwise).
Either way, the legacy API receives basic auth credentials and returns the data which
then in turn is returned and presented to the user.

To install and run the showcase application without any interference of
the operator or the rest of the solution, follow the installation guide
in the readme on <https://github.com/WirePact/poc-showcase-app>.
To install and use the whole PoC solution, please refer to the installation guide
in the Appendix.

### Operator

> TODO

### Envoy Sidecar

> TODO

### Translator

> TODO
