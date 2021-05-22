# State of the Art and the Practice

This section gives an overview of the current state of the art and the practice. Furthermore, it states the deficiencies that this project tries to solve.

## State of the Art

In cloud environments, a solved problem is the transmission of arbitrary data from one endpoint to another. Modern programming languages (like .NET, Python and Node.js) provide ways to handle communication with other endpoints and APIs. To transmit data between services in a cloud environment, an application can use the HTTP protocol or gRPC^[<https://grpc.io/>] to encode the requests and responses in a common format. In the case of a service mesh, a sidecar is injected into the pod that contains a proxy to handle data transmission between the services.

In terms of authentication and authorization, there is a variety of schemes that enable an application to authenticate and authorize its users. OpenID Connect (OIDC) (see {@sec:auth_oidc}) is a modern authentication scheme, that extends the OAuth 2.0 framework, which in turn handles authorization [@spec:OIDC]. OAuth only defines how to grant access to specific resources (like APIs) but not how they are exchanged. OIDC fills that space by introducing authentication flows (e.g. "Authorization Code Flow" in {@fig:oidc_code_flow}). OAuth in combination with OIDC provides a modern and secure way of authentication and authorizing users against an API.

Modern software architectures that are specifically designed for the cloud are called "Cloud Native Applications" (CNA). @kratzke:CloudNativeApplications define a CNA as:

> "A cloud-native application is a distributed, elastic and horizontal scalable system composed of (micro)services which isolates state in a minimum of stateful components. The application and each self-contained deployment unit of that application is designed according to cloud-focused design patterns and operated on a self-service elastic platform."

However, with CNAs and the general movement to cloud environments and digitalization, not all applications get that chance to adjust. For various reasons like budget, time or technical risks and skill availability, legacy applications and monoliths are not always refactored or re-written before they are deployed into a cloud environment. If the legacy applications (for example an old ERP system) are mixed with modern systems, then the need of "translation" arises. Assuming that the modern part is a secure application that uses OIDC to authenticate its users and the application needs to fetch data from a legacy system. The legacy application does not understand OIDC, thus either the modern or the legacy application must receive code changes (i.e. enable the application to convert the user credentials to the scheme of the target service) to enable communication between the services. Following the previous assumption, the code changes will likely be introduced into the modern application, since it is presumably better maintainable and deployable than the legacy app. Hence, the modern application receives changes that may introduce new bugs or vulnerabilities. If new code is introduced into an application, "normal" software bugs may be created and external dependencies (such as libraries for authentication and authorziation) may import vulnerabilities caused by bugs or by deviation from the standards.

![Microservice Architecture that contains modern applications as well as legacy services.](diagrams/component/is-solution-showcase.puml){#fig:is_solution_components short-caption="Microservice Architecture with legacy components"}

We consider the components in {@fig:is_solution_components}:

- **User**: A person with access to the application
- **Single Page Application**: A modern single page application (SPA)
- **Identity and Access Management (IAM)**: Identity Provider for the solution (does not necessarily reside in the same cloud)
- **Cloud Native Application (CNA)**: A modern API application and primary access point for the client
- **Legacy System**: Legacy service that is called by service a to fetch some additional data

In the practice, we encountered the stated scenario at various points in time. Legacy services may not be the primary use-case, another one is the usage of third-party applications without any access to the sourcecode.

![Current state of the art of accessing legacy systems from modern services with differing authentication schemes.](diagrams/sequences/is-solution-process.puml){#fig:is_solution_process short-caption="Current process of legacy communication"}

The invocation sequence in {@fig:is_solution_process} shows the process of communication in such a scenario. In {@fig:is_solution_process}, the SPA authenticates against an arbitrary IAM. The CNA is the modern backend that supports the SPA as a backend API. Therefore, the CNA provides functionality for the SPA. The legacy application, for example an old ERP with order information, was moved into the cloud, but is not refactored nor rewritten to communicate with modern authentication technologies.

In this scenario, the SPA calls some API on the CNA that then will call the legacy system to get additional information to present to the user. Since the SPA and the CNA communicate with the same authentication technology, the call is straightforward. The SPA authenticates itself and obtains an access token. When calling the service (the CNA), the token is transmitted and the service can check with the IAM if the user is authorized to access the system. When the CNA then calls the legacy system for additional information, it is required to translate the user-provided credentials to a format that the legacy system understands. In the example, the legacy system is only able to handle Basic Authentication (RFC7617), as explained in {@sec:basic_auth}. This means, if the CNA wants to communicate with the legacy system, it must implement some translation logic to change the user credentials into the typical Basic Authentication Base64 encoded format of `<Username>:<Password>`. Hence, code changes are introduced to the CNA since the legacy system is not likely to be easily maintainable.

## Current Software and Concepts

In practice, no current solution exists that allows credentials to be transformed between authentication schemes. The service mesh "Istio" provides a mechanism to secure services that communicate with mTLS (mutual TLS) [@istio:website:mtls] as well as an external mechanism to provide custom authentication and authorization capabilities [@istio:website:custom-authz]. The concept of Istio works well when all applications in the system share the same authentication scheme. As soon as two or more schemes are in place, the need for transformation arises again.

In terms of API gateways, Envoy provides mTLS and the external authentication. In fact, Istio uses Envoy as sidecar proxy to use this feature. Another prominent API gateway, "NGINX"^[<https://www.nginx.com/>], implements a similar external authentication mechanism [@nginx:website:ext-authz]. However, Envoy implements a more fine grained control over the HTTP request. As an external authentication service for Envoy, the result may change HTTP headers in the request and the response.

There exist techniques, such as SAML (Security Assertion Markup Language), to transmit an identity of a user to other services. However, SAML only describes the format of the identity itself, not the translation between varying credentials. SAML works when all participating services understand SAML as well. If a legacy system is not able to parse and understand SAML, the same problem arises.

All the discussed technologies and applications above do not support the dynamic conversion of user credentials. While Istio solves the communication and enables mTLS between services, it is not able to translate credentials between services. SAML gives a common format for an identity of a user, but it is an authentication scheme on its own and thus the "translation problem" still exists.

## Deficiencies {#sec:deficiencies}

The situation described in the previous sections introduces several problems. It does not matter whether the legacy system is a third party application to which no code changes can be applied to, or if it is an application that cannot be updated for the time being. Most likely, the code change to provide the ability to communicate will be introduced into the CNA. This adds the risk of errors since new code must be produced, which would not be necessary if the legacy service was refactored. Also, changing the CNA to communicate with B may be a feasible solution in a small setup. But as the landscape of the application grows, this solution does not scale well.

![Matrix Problem in Service Landscape](diagrams/component/matrix-problem.puml){#fig:matrix_problem}

The matrix problem, as depicted in {@fig:matrix_problem}, shows that the number of conversion mechanisms increases with each service and each authentication method. As the landscape and the different methods of authentication grow, it is not a feasible solution to implement every authentication scheme in all the services. In {@fig:matrix_problem}, "Caller 1" is required to transform the user credentials into four different formats to communicate with service one to four. When another caller enters the landscape, it must implement the same four mechanisms as well.

Another issue that emerges with this transformation of credentials: The credentials leak into the trust zone. As long as each service is in the same trust zone (for example in the same data-center in the same cluster behind the same API gateway), this may not be problematic. As soon as the communication is between data centers, the communication and the credentials must be protected. It is not possible to create a zero trust (assumption, that an attacker is always present, see {@sec:zero-trust}) environment with the need of knowledge about the target's authentication schemes.

Service meshes may provide a way to secure communication between services, but they are not able to transform credentials to a required format for any legacy application yet. It would be a possible solution to enable service meshes to transform credentials. However, normally service meshes introduce another layer of complexity on top of the environment.

Other technologies - such as credential vaults - provide a similar problem. The vault is the central weakness in the system. If the vault is attacked, the whole trust zone may fail. While a credential vault would provide a way to share credentials between services, it does not mitigate the need of transformation of credentials. A vault, like "Vault by HashiCorp"^[<https://www.vaultproject.io/>] typically provides a secure way to inject credentials into a system. The vaults do not transform credentials for the destination.
