# State of the Art, the Practice and Deficiencies

This section gives an overview over the current state of the
art, the practice, as well as the deficiencies to an optimal situation.
Furthermore this section states an assessment of the current
practice and the solutions found.

## State of the Art

In cloud environments, a problem which is well solved is the
transmission of data from one point to another. Kubernetes, for example,
uses "Services" that provide a DNS name for a specified workload.
In terms of authentication and authorization, there exist a variety
of schemes that enable an application to authenticate and authorize
their users. OpenID Connect (OIDC) (see {@sec:auth_oidc}) is a modern authentication
scheme, that builds upon OAuth 2.0, that in turn handles authorization
[@spec:OIDC].

Modern software architectures that are specifically designed for the cloud are called
"Cloud Native Applications" (CNA). @kratzke:CloudNativeApplications define
a CNA as:

> "A cloud-native application is a distributed, elastic and horizontal
> scalable system composed of (micro)services which isolates state in a minimum
> of stateful components. The application and each self-contained deployment unit
> of that application is designed according to cloud-focused design patterns and
> operated on a self-service elastic platform." [@kratzke:CloudNativeApplications, sec. 3].

However, with CNAs and the general movement to cloud environments, not all applications
get that chance to adjust. For various reasons like budget, time or complexity,
legacy applications and monoliths are not refactored
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
but there exist other reasons to have the need of using a translation of credentials.
Another case is the usage of third party applications which only support
certain authentication mechanisms.

![Current state of the art of accessing legacy systems from
modern services with differing authentication schemes.
](diagrams/sequences/is-solution-process.puml){#fig:is_solution_process
short-caption="Current process of legacy communication"}

The process in {@fig:is_solution_process} shows the process of communication
in such a described scenario. In
{@fig:is_solution_process}, the "Client" is the single page application (SPA),
that authenticates against an arbitrary Identity and Access Management System (IAM).
"Service A" is the modern backend that supports the client as backend API.
Therefore, "Service A" provides functionality for the client. "Service B" is
a legacy application, for example an old ERP with order information, that
was moved into the cloud, but is not refactored nor rewritten to communicate
with modern authentication technologies.

In this scenario, the client calls some API on "Service A" that then
will call "Service B" to get additional information to present to the
user. Since the client and "Service A" communicate with the same authentication
technology, the call is straight forward. The client authenticates himself
and obtains an access token. When calling the service ("Service A"),
the token is transmitted and the service can check with the IAM if the user
is authorized to access the system. When "Service A" then calls "Service B"
for additional information, it needs to translate the user provided credentials
to a format that "Service B" understands. In the provided example, "Service B"
is only able to handle Basic Authentication, as explained in {@sec:basic_auth}.
This means, if "Service A" wants to communicate with "Service B", it must implement
some translation logic to change the credentials to a format that B understands.
This introduces code changes to "Service A", since "Service B" is a legacy
application that is not maintainable.

## The Practice

In practice, no current solution exists, that allows credentials to be transformed
between authentication schemes. The service mesh "Istio" provides a mechanism to
secure services that communicate with mTLS (mutual TLS) as well as an external
mechanism to provide authentication and authorization capabilities. This works well
when all applications in the system share the same authentication scheme. As soon
as two or more schemes are in place, the need for transformation arises again.

## Deficiencies

The situation described in the previous sections introduces several problems.
It does not matter if "Service B" is a third party application to which
no code changes can be applied to, or if it is a legacy application that
cannot be updated for the time being. Most likely, the code change to provide
the ability to communicate will be introduced into "Service A". This
adds the risk of errors since new code must be produced, which would
not be necessary if the legacy service would be refactored.
Also, changing "Service A" to communicate with B may be a feasible solution
in a small setup. But as the landscape of the microservice architecture
grows, this solution does not scale well. The matrix problem
$X \text{ services} * Y \text{ authentication methods}$ describes this
problematic. As the landscape and the different methods of authentication
grows, it is not a feasible solution to implement each and every authentication
scheme in all the services.

Another issue that emerges with this transformation of credentials:
The credentials leak into the trust zone. As long as each service
is in the same trust zone (for example in the same data-center in the same
cluster behind the same API gateway), this may not be problematic. As soon
as communication is between data centers, the communication and the credentials
must be protected. It is not possible to create a zero trust environment with
the need of knowledge about the targets authentication schemes.

The usage of a service mesh to mitigate the problem is not an option since the
initial problem of transforming credential still persists. Service meshes may
provide a way to secure communication between services, but they are not able
to transform credentials to a required format for any legacy application.
Furthermore, service meshes introduce configurational complexity to the system which, in our
opinion, is not needed without a clear usecase for a service mesh.
