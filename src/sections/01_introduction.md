# Introduction

Modern cloud environments solve many problems like the discovery of
services and data transfer or communiation between services
in general. One modern way of solving service discovery and communication
is a Service Mesh, which introduces an additional infrastructure
layer that manages the communication between services [@li:ServiceMesh, section 2].

However, a specific problem is not solved yet: "dynamic" trusted communication between
services. When a service, that is capable of handling OpenID Connect (OIDC)
credentials, wants to communicate with a service that only knows Basic Authentication
that originating service must implement some sort of conversion or know
static credentials to communicate with the basic auth service.
Generally, this introduces changes to the software of services. In small
applications which consist of one or two services, implementing this
conversion may be a feasable option. If we look at an application which
spans over a big landscape and a multitude of services, implementing each
and every possible authentication mechanism and the according conversions
will be error prone work and does not scale well^[According to the matrix problem:
X services times Y authentication methods].

The goal of the project "Distributed Authentication Mesh" is to provide a solution
for this problem. TODO.

## Project Context

This project aims at the specific problem of declarative conversion
of credentials to ensure authorized communication between services.
The solution may be runnable on various platforms but will be implemented
according to Kubernetes standards. Kubernetes^[<https://kubernetes.io/>] is an
orchestration platform that works with containerized applications.

The deliverables of this project may be used to ensure services can
communicate with each other despite their different authentication
mechanisms. As an example, this could be used to enable a modern
web application that uses OIDC as the authentication and authorization
mechanism to communicate with a legacy application that was deployed
on the Kubernetes cluster but not yet rewritten.

- sidecar?

TODO.
