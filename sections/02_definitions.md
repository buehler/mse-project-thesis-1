# Definitions and Boundaries

This section provides information about the project.
It gives an overview of the context as well as terminology
and general definitions.

## Context

This project aims at the specific problem of declarative conversion
of credentials to ensure authorized communication between services.
The solution may be runnable on various platforms but will be implemented
according to Kubernetes standards. Kubernetes^[<https://kubernetes.io/>] is an
orchestration platform that works with containerized applications.

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

briefly describe kubernetes
![Container Evolution](images/Kubernetes/Container_Evolution.png)
-> fetched from github repo with CCBY4.0 lizenz!

### Operator

briefly describe what an operator is

### Service Mesh

briefly describe a service mesh.

## Authentication and Authorization

### Basic

### OpenID Connect (OIDC)

briefly describe OIDC
