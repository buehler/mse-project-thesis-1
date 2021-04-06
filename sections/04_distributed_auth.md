# Distributed Authentication Mesh

This section gives a general overview of the proposed solution. Furthermore,
boundaries of the solution are provided along with common software engineering elements
like requirements, non-functional requirements and the documentation of the architecture.

The proposed architecture may be used as generic description for a solution to the
described problem. For this project, the solution is implemented specifically to work
within a Kubernetes cluster.

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

## Standards and Best Practices

## Contrast

### SAML

### WS-\*

Show that this project is not a protocol contract like WS-\*.

## Architecture

### Brief Description

### UseCases

### Application Domain

### Sequences

### Communication

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
