# Evaluation {#sec:evaluation}

This section evaluates the concepts and the architecture of {@sec:solution}. The main goal is to show that the proposed solution can improve the current situation and does not introduce security issues when used.

## Architecture against Requirements

To show that the architecture of the distributed authentication mesh has the potential to improve the developer experience and the current situation with legacy or third-party software, we compare the architecture against the non-functional requirements established in {@sec:solution}.

### NFR 1: Improve Security

> NFR1: First and foremost, the solution must not be less secure than current solutions.

Without the distributed authentication mesh, credentials like access tokens or basic authentication credentials are transmitted in the HTTP headers. This is a well-known way of authorizing requests [@RFC1945]. If the current standard is regarded "secure" — not judging by the authorization scheme — then the mesh is secure as well. It even improves security by hiding the original credentials.

In the PoC, the credentials are still transmitted. The PoC is responsible to show that modifying HTTP headers during a request is possible. Securing the implementation of the concept is not part of this project.

### NFR 2: Secure implementation

> NFR 2: The solution must adhere to current best practices and security mechanisms. Furthermore, it must be implemented according to the standards of the practice to mitigate security issues as stated in the OWASP Top Ten (https://owasp.org/www-project-top-ten).

The following list shows the OWASP top ten security issues with the comparison to the architecture:

1. Injection: The distributed authentication mesh does not use any database or LDAP features. Thus, there is no attack vector for an injection attack.
2. Broken Authentication^[Broken Authentication relates to incorrectly implemented authentication and session management. This would allow attackers to compromise sessions and passwords.]: The mesh does not implement a security scheme by itself. The only part that can be targeted by broken authentication attacks is the transformer. Developers of each translator are responsible to adhere to the OWASP principles and state-of-the-art security mechanisms.
3. Sensitive Data Exposure: The transmitted user identity must not include sensitive data. Sensitive data, such as financial or healthcare data is not part of a user identity and not needed for the mesh. Data, such as the user id or the name of a user, may be transmitted.
4. XML External Entities: The mesh does not use XML.
5. Broken Access Control: The mesh only provides valid credentials for the target system. It is not responsible for the authorization and enforcement of rules. The application that uses the mesh is responsible to enforce authorization rules.
6. Security Misconfiguration: The mesh does not directly influence used authentication schemes. However, the translators are directly responsible to use the correct HTTP headers for the target authentication mechanism. Developers of translators therefore responsible to correctly implement the authentication schemes.
7. Cross-Site Scripting (XSS): The mesh is not part of any public-facing application. No code gets executed. Therefore, XSS is not possible.
8. Insecure Deserialization: Under the assumption that JWT is used to transmit the user identity between participating elements, this flaw is negated. The validation and deserialization of JSON does not execute any code since JSON cannot transmit executable data. The translator must not execute any data it receives from the JWT.
9. Using Components with Known Vulnerabilities: This may be an issue if developers of translators do not update their software. The translator is the "moving part" of the mesh, which can be implemented by other developers as well. Developers must update their translators to eliminate this issue.
10. Insufficient Logging & Monitoring: This issue cannot be validated based on the architecture of the mesh. Since there is no production-ready implementation, logging is a part of the future work.

As the list above shows, the architecture does eliminate or out-source the OWASP issues. Translators must be implemented with special care to adhere to the security standards.

### NFR 3: Generic Usage

> NFR 3: The concept of the solution is applicable to cluster orchestration software other than Kubernetes. The architecture provides a general way of solving the stated problem instead of giving a proprietary solution for one vendor. The concept should even be realizable for non-orchestration platforms like a Windows operating system.

The abstract architecture in {@sec:solution} is generic. All components may be implemented on any platform and with any programming language of choice. The automation engine is optional so that the proposed concept may be implemented as a macOS or Windows software. There is no special requirement for any part of the mesh that ties the solution to a specific vendor.

### NFR 4: Performance Impact

> NFR 4: The translation of the credentials should not extensively impact the timeframe of an arbitrary request. In production mode, the additional time to check and transform the credentials should not exceed 100ms. This is a general recommendation and some authentication mechanism may exceed the stated 100ms.

The architecture does not give hints about the effective performance impact. This generally depends on the used authentication scheme and the implementation of the transformer. Each transformer is responsible to achieve this goal. The solution is — theoretically — not limited in execution time, but to function as a production-ready solution, it must not impact the execution time of requests significantly.

### NFR 5: Modularity

> NFR 5: The solution must be extensible with additional “translators” that provide the means of transforming the given credentials to other target formats.

The architecture shows that the translator is a component that is orchestrated by the automation engine. The translators should target one specific authentication scheme and can be implemented in any language or framework. They must only adhere to the principles of the mesh. It is not defined how the communication between the proxy and the translator takes place. In the PoC, Envoy (as the proxy) has a well-defined gRPC definition for such communication. Further work may contain the definition of translators for the automation engine. Using Envoy and the gRPC definition is a feasible option to implement a production-ready version of the mesh when using a cloud environment.

### NFR 6: Integration into Infrastructure

> NFR 6: The solution may run with or without a service mesh. It is a goal that the solution can run without a service mesh to reduce the overall complexity, but if a service mesh is already in place, the solution must be able to work with the provided infrastructure.

The shown architecture in {@sec:solution} does not interfere with a service mesh. If a service mesh is already deployed on a cloud environment, the automation engine must configure/reuse the parts that are already given by the service mesh.

### NFR 7: Scalability

> NFR 7: The architecture must be scalable. In a cloud-native environment, the application that is enhanced may be scaled. Therefore, the solution must be able to scale with the application as well.

{@sec:solution} shows that the automation engine does enhance Kubernetes pods. A pod is one unit of deployment. When a pod is scaled by Kubernetes, all containers in the pod do scale as well. Since all parts of the mesh are complete packages, they do scale with the pod.

### NFR 8: Separation of Concerns

> NFR 8: Each translator should only handle one authentication scheme to ensure separation of concerns and scalability of the whole solution.

The architecture does not define the effective implementation of the translators. Each translator can be written in any language or framework. The responsibility to adhere to the separation of concerns is handed over to the developers of translators.

### NFR 9: No Data-Transfer

> NFR 9: The solution depends on an external software for data transmission. The solution must not interfere with the data plane. Error handling of the data plane is handled by the external application.

The proxy and translator only modify HTTP headers. The effective transmission of the data between the parties is not part of the authentication mesh. As such, error handling for the transmission is also out-sourced to the used proxy software.

### NFR 10: Error Handling

> NFR 10: The solution handles errors in the translation and the automation engine according to the architectural description.

All parts of the distributed authentication mesh rely on external software, except for translators. The automation engine is optional and if it fails, the underlying system is responsible to restart the engine. The source and destination services are not in the responsibility of the mesh by themselves. In the PoC, the proxy is an Envoy instance that contains error handling for the data-transfer. In addition, Kubernetes provides error handling for non-running applications and is responsible for the running state of the applications.

The only critical elements in the authentication mesh are translators. Since they are custom implementations, they must contain error handling for the requests. Translators receive HTTP headers and must parse some user identity out of it. If a translator is not able to construct the necessary HTTP headers for the destination, the request must fail. If any other error occurs (e.g. user repository not accessible) the request must fail as well.

{@sec:solution} states that in the case of a timeout, error, or invalid data, the request must be blocked by the translator. Only valid requests must be let through to the destination.

## Leaking Credentials and Developer Experience

As stated in {@sec:state_of_the_art}, when applications with diverging authentication schemes communicate with each other, they must transmit credentials to the destination. Otherwise, it would not be possible to authenticate a user in each system.

The distributed authentication mesh replaces the need of effective credentials in communication with federated identity. Similar to SAML (explained in {@sec:solution}), an encoded identity is transmitted with the request instead of user credentials such as passwords or access tokens. This identity is then translated to effective credentials in the translator and ultimately forwarded to the target application.

Another identified problem in {@sec:state_of_the_art} is the introduction of code changes when the use case for the authentication mesh arises. To enable "modern software" to talk with "legacy software" (or third-party software), most likely the modern software will implement the translation logic. This may introduce bugs and does not scale when the service landscape grows.

The proposed concept enables developers to declaratively (via configuration) transform such credentials between applications. When used in a cloud environment, the automation engine can take care of all moving parts. With the solution in place, a developer is only required to configure the application as part of the mesh and the automation engine will inject the needed proxy and translators. After the automation step has taken place, the application is enhanced with additional authentication schemes without implementing the effective translation.

Therefore, the distributed authentication mesh enhances the general security of a system by removing the need of transmitting credentials to other services. Also, the developer experience is improved by allowing software developers to configuratively add authentication schemes to their software instead of manually developing conversion mechanisms for credentials.
