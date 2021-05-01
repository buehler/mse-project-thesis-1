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
diagrams with explanations. First, a description of the solution gives an intro
about the idea, then the architecture shows the general overview of the solution
followed by sequence and communication definitions.

The reader should note, that the proposed architecture does not match the implementation
of the PoC to the full extent. The goal of this project is to provide a generalizable idea
to implement such a solution, while the PoC proves the ability of modifying HTTP requests
in-flight.

### Brief Description

In general, when some service wants to communicate with another service and the user does not
need to authenticate himself for every service, a federated identity is used. This means, that
at some point, the user validates his own identity and is then authenticated in the whole zone of
trust.

To achieve such a federated identity with diverging authentication schemes, the solution
converts validated credentials to a common language format. This format, in conjunction with
a proof of the sender, validates the identity over the wire in the communication between services
without the need of additional authentication. When all parties of a communication are trusted
through verification, no information about
the effective credentials may leak into the communication between services.

The basic idea of the solution is to remove any credentials from an outgoing HTTP request with
the common format of the users identity and replace the common format in the ingoing HTTP
request into the valid credentials of the given scheme.

In the case of Kubernetes, this additional software is injected via an operator as a sidecar.
The operator watches for creation of deployments and services and orchestrates the configuration
of the sidecars. The application gets a sidecar for the communication (an Envoy proxy) and
for each authentication scheme that the target service supports, it receives a "translator"
sidecar that handles the conversion from the common format to the specific scheme.

### Use Case

The usefulness of such a solution shows when "older" or monolythic software moves to the cloud
or when third party software is used that provides no accessable source code.

**Communicate with legacy software**

Precondition: Cloud native application and legacy software are deployed with
their respective manifests and the sidecars are running.

1. The user is authenticated against the CNA
2. The user tries to access a resource on the legacy software
3. The CNA creates a request and "forwards" the credentials of the user
4. The envoy proxy intercepts the request and forwards the credentials to the transformer
5. The transformer verifies the credentials and transforms them into a common format
6. The envoy proxy replaces the headers and forwards the request
7. The receiving envoy proxy forwards the common format to the translator of the target
8. The translator casts the credentials into the specific authentication scheme credentials
9. The receiving envoy proxy forwards the request with the updated HTTP headers

Postcondition: The communication has taken place and no credentials have left the source
service (CNA). Furthermore, the legacy service does not know, what credentials or what specific
authentication scheme was used.

This use case can be changed such that the receiving service is not a legacy software but
an old and non-maintained application that is deployed into a cloud environment without refactoring.

### System Architecture

In this section, we describe the system architecture of the proposed solution.
The architecture is shown in a diagram and then broken down to the individual parts.

![System Architecture](diagrams/component/system-architecture.puml){#fig:system_architecture}

As can be seen in {@fig:system_architecture}, the overall structure is within a cloud environment.
The proposed solution may not only run in cloud environments, but the initial idea orginates from
the stated problem which occurs in cloud environments. Inside the cloud environment an operator that
has access to the deployments manages the additional sidecars. The operator is responsible for
adding the different needed sidecars as well as the configuration of them.

The "Key Manager" operates as public and private key store and orchestrator of those keys.
Whenever a new service joins the authentication mesh, the key manager creates a new public / private
key pair for the service and securely stores them. The public key will be available for access for
other services to validate the signature of the transmitted identity.

Within the deployment there exist two sidecars, one "Envoy" proxy and a "Credential Translator".
Envoy acts as inbound and outbound proxy for the software and intercepts HTTP calls from and to the software
to manipulate the HTTP headers. The translator will transform the identity in the given common
domain format into the needed format of the software. If multiple formats are configurable,
then multiple transformer will be present since one transformer may only handle one format to
reduce the load impact.

#### Operator

> TODO: describe the operator

#### Key Manager

> TODO: describe the key manager

#### Envoy Proxy

> TODO: describe the envoy config

#### Translator

> TODO: describe the translator architecture

### Communication

The communication between the envoy proxies must be secured. Furthermore, the identity that
is transformed over the wire must be tamper proof. Two established formats would suffice:
"SAML" and "JWT Tokens". While both contain the possibility to hash their contents and
thus secure them against modification, JWT tokens are better designed for HTTP headers,
since in current OIDC environments, JWT tokens are already used as access and/or identity tokens.
They provide a secure environment with public and private claim names [@RFC7519, sec. 4.2, sec. 4.3].

Other options could be:

- Simple JSON
- YAML
- XML
- Any other structured format

The problem with other structured formats is that tamper proofing must be done manually.
JWT tokens provide a specified way of attaching a hashed version of the whole
content [@RFC7519] and therefore provide a method of validating a JWT token if it is
still valid and if the sender is trusted. The receiving end can fetch a public key
from the origin and then validates the signature. If the signature is correct, the JWT
token has been issued by a trusted and registered instance of the authentication network.

## Implementation Proof of Concept (PoC)

To provide a proof that the general idea of the solution is possible,
a PoC is implemented during the work of this project. The PoC addresses
the following risks and questions:

- Is it possible intercept HTTP requests to an arbitrary service
- Is it further possible to modify the HTTP headers of the request
- Can a sidecar service transform given credentials from one format to another
  - In the PoC, an OIDC access token is translated into static basic auth credentials
  - No common language format is implemented or used in the PoC
- Can a custom operator inject the following elements
  - The correct configuration for Envoy to use external authentication
  - The translator module to transform the credentials

Based on the results of the PoC, the following further work may be realized:

- Specify the concrete common domain language to transport identities
- Implement a secure way of transporting identities that is tamper-proof
- Provide a production ready solution of some translators and the operator
- Integrate the solution with a service mesh
- Provide a production ready documentation of the solution
- Further investiage the possibility of hardening the communication between services
  (e.g. with mTLS)

The following sections will describe the parts of the PoC and their specific
implementation details.

### Showcase Application

The showcase application is a demo application to show the need and the particular
usecase of the solution. The application resides in an open source repository
under <https://github.com/WirePact/poc-showcase-app>.

When installed in a Kubernetes cluster,
the user can open (depending on the local configuration) the URL to the frontend
application^[In the example it is https://kubernetes.docker.internal since
this is the local configured URL for "Docker Desktop"].

![Component Diagram of the Showcase Application
](diagrams/component/showcase-app.puml){#fig:impl_components_showcase_app}

{@fig:impl_components_showcase_app} gives an overview over the components
in the showcase application. The system contains an ASP.Net Razor Page^[
<https://docs.microsoft.com/en-us/aspnet/core/razor-pages/>]
application as the frontend, an ASP.Net API application with
configured Zitadel^[<https://zitadel.ch>] OIDC authentication as "modern" backend
service and another ASP.Net API application that only supports basic authentication
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

### Envoy Sidecar

### Translator

### Operator

### PoC Composition

> TODO: Explain the whole PoC composition (how to run and stuff with operator).
