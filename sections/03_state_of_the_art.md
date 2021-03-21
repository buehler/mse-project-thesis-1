# State of the Art, the Practice and Deficiencies

This section gives an overview over the current state of the
art, the practice, as well as the deficiencies according to the author.
Furthermore this section states an assessment of the current
practice and the solutions found.

## State of the Art

In cloud environments, a problem that is well solved is the
transmission of data from one point to another. Kubernetes, for example,
uses "Services" that provide a DNS name for a specified workload.
In terms of authentication and authorization, there exist a variety
of schemes that enable an application to authenticate and authorize
their users. OpenID Connect (OIDC) (see {@sec:auth_oidc}) is a modern authentication
scheme, that builds upon OAuth 2.0, that in turn handles authorization
[@sakimura:OIDCCore].

Modern software architectures that are specifically designed for the cloud are called
"Cloud Native Applications" (CNA). @kratzke:CloudNativeApplications define
a CNA as:

> "A cloud-native application is a distributed, elastic and horizontal
> scalable system composed of (micro)services which isolates state in a minimum
> of stateful components. The application and each self-contained deployment unit
> of that application is designed according to cloud-focused design patterns and
> operated on a self-service elastic platform." [@kratzke:CloudNativeApplications, sec. 3].

However, with CNAs and the general movement to cloud environments, not all applications
get that chance to adjust. For various reasons
like budget, time or complexity, legacy applications and monoliths are not refactored
or re-written before they are deployed into a cloud environment. If the legacy applications
are mixed with modern systems, then the need of "translation" arises. Assuming, that
the modern part is a secure application, that uses OIDC to authorize its users
and the application needs to fetch data from the legacy system that does not understand
OIDC, code changes must be made. Following the previous assumption, the code changes
will likely be introduced into the modern application, since it is better maintainable
and deployable than the legacy monolith. Hence, the modern application receives changes
that may introduce new bugs or security vulnerabilities.

![Microservice Architecture that contains modern applications as
well as legacy services.](diagrams/component/is-solution-showcase.puml){#fig:is_solution_components
short-caption="Microservice Architecture with legacy components"}

We consider the components in {@fig:is_solution_components}:

- **User**: A person with access to the application
- **Client**: A modern single page application (SPA)
- **IAM**: Identity Provider for the solution (does not necessarily reside in the same cloud)
- **Service A**: A modern API application and primary access point for the client
- **Service B**: Legacy service that is called by service a to fetch some additional data

The stated scenario is quite common. Legacy services may not be the primary use-case,
but there exist other reasons to have the need of using TODO

![Current state of the art of accessing legacy systems from
modern services with differing authentication schemes.
](diagrams/sequences/is-solution-process.puml){#fig:is_solution_process
short-caption="Current process of legacy communication"}

The process in {@fig:is_solution_process} shows such a describe scenario. In
{@fig:is_solution_process}, the "client" is a single page application (SPA),
that authenticates against an arbitrary Identity and Access Management System (IAM).
"Service A"

TODO: describe the process better

## Deficiencies

asdf
