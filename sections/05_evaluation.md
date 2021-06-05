# Evaluation

This section evaluates the concept and the architecture of {@sec:solution}. The main goal is to show that the proposed solution can improve the current situation and does not introduce security issues when used. Since the architecture is only conceptional, the evaluation comes in a theoretical manner.

## Architecture against Requirements

To show that the architecture of the distributed authentication mesh does improve the developer experience as well as the current situation with legacy or third-party software, we compare the architecture against the non-functional requirements in {@tbl:non-functional-requirements}.

### NFR 1: Improve Security

> NFR 1: First and foremost, the solution must not be less secure than current solutions.

Currently, without the distributed authentication mesh, credentials like access tokens or basic authentication credentials are transmitted in the HTTP headers. This is a well-known way of authorizing requests [@RFC1945]. If the current standard is viewed as "secure" - not judging by the authorization scheme - then the mesh is secure as well. It even improves security by hiding the original credentials. This prevents man-in-the-middle attacks and leakage of credentials.

In the POC, the credentials are still transmitted. The POC is responsible of proving that modifying HTTP headers during a request is possible. Securing the system is part of further work.

### NFR 2: Secure implementation

> NFR 2: The solution must adhere to current best practices and security mechanisms. Furthermore, it must be implemented according to the standards of the practice to mitigate security issues as stated in the OWASP Top Ten (https://owasp.org/www-project-top-ten).

The following list shows the OWASP top ten security issues with the comparison to the architecture:

1. Injection: The distributed authentication mesh does not use any database or LDAP features. Thus, there is not attack vector for any injection attack.
2. Broken Authentication: The mesh does not implement a security scheme by itself. The only part that can be targeted by broken authentication attacks is the transformer. Developers of each translator must adhere to the current standards to mitigate this problem.
3. Sensitive Data Exposure: The transmitted user identity must not include sensitive data. Sensitive data, such as financial or healthcare data is not part of a user identity and therefore, not needed for the mesh. Data, such as the user id or the name of a user, may be transmitted.
4. XML External Entities: The mesh does not use XML.
5. Brocken Access Control: The mesh only provides valid credentials for the target system. It is not responsible for authorization and enforcement of rules. The application that uses the mesh is responsible to enforce authorization rules.
6. Security Misconfiguration: The mesh does not directly influence used authentication schemes. The identity of the user is transmitted via custom HTTP header, which is consumed on the receiving side of the communication. Each translator is responsible to create the appropriate HTTP headers for its destination.
7. Cross-Site Scripting (XSS): The mesh is not part of any public-facing application. No code gets executed. Therefore, XSS is not possible.
8. Insecure Deserialization: Under the assumption that JWT are used to transmit the users identity between participating elements, this flaw is eliminated. The validation and deserialization of JSON does not execute any code since JSON cannot transmit executable data. The translator must not execute any data it receives from the JWT.
9. Using Components with Known Vulnerabilities: This may be an issue if developers of translators do not update their software. The translator is the "moving part" of the mesh, which can be implemented by other developers as well. Developers must update their translators to eliminate this issue.
10. Insufficient Logging & Monitoring: This issue cannot be validated based on the architecture of the mesh. Since there is no production-ready implementation, logging is a part of the future work.

As the list above shows, the architecture does eliminate or out-source the top ten OWASP issues. Translators must be implemented with special care to not execute any code or leak credentials to the world.

### NFR 3: Generic Usage

> NFR 3: The concept of the solution is applicable to cluster orchestration software other than Kubernetes. The architecture provides a general way of solving the stated problem instead of giving a proprietary solution for one vendor. The concept should even be realizable for non-orchestration platforms like a Windows operating system.

The architecture in {@sec:abstract_architecture} is generic. All components may be implemented on any platform and with any programming language of choice. The automation engine is optional so that the proposed solution may be implemented as a macOS or Windows software. There is no special requirement for any part of the mesh that ties the solution to a specific vendor. {@sec:specific_architecture} shows an example of the architecture in the context of Kubernetes.

### NFR 4: Performance Impact

> NFR 4: The translation of the credentials should not extensively impact the timeframe of an arbitrary request. In production mode, the additional time to check and transform the credentials should not exceed 100ms. This is a general recommendation and some authentication mechanism may exceed the stated 100ms.

The architecture does not give hints about the effective performance impact. This generally depends on the used authentication scheme as well as the implementation of the transformer. Each transformer is responsible to reach this goal. The solution is - theoretically - not limited in execution time, but to function as a production-ready solution, it must not impact the execution time of requests significantly.

### NFR 5: Modularity

> NFR 5: The solution is modular. It is extensible with additional "translators", that provide the means of transforming the given credentials to other target formats.

The architecture shows that the translator is a component that is orchestrated by the automation engine. These translators should target one specific authentication scheme and can be implemented in any language or framework. They must only adhere to the principles of the mesh. It is not defined how the communication between the proxy and the translator takes place. In the POC, Envoy (as the proxy) has a well defined gRPC definition for such a communication. Further work may contain the effective definition of translators for the automation engine.

### NFR 6: Interoperability

> NFR 6: The solution may run with or without a service mesh. It is a goal that the solution can run without a service mesh to reduce the overall complexity, but if a service mesh is already in place, the solution must be able to work with the provided infrastructure.

The shown architecture in {@sec:abstract_architecture} does not interfere with a service mesh. If a service mesh is already deployed on a cloud environment, the automation engine should configure/reuse the parts that are already given by the service mesh.

### NFR 7: Scalability

> NFR 7: The architecture must be scalable. The provided software must be able to scale according to the business needs of the overall system.

{@sec:specific_architecture} shows that the automation engine does enhance Kubernetes pods. A pod is one unit of deployment. When a pod is scaled by Kubernetes, all containers in the pod do scale as well. Since all parts of the mesh are complete packages, they do scale with the pod.

### NFR 8: Separation of Concerns

> NFR 8: Each translator should only handle one authentication scheme to ensure the separation of concerns and scalability of the whole solution.

The architecture does not show the effective implementation of the translators. Developers that implement translators are responsible to adhere to this requirement.

### NFR 9: No Data-Transfer

> NFR 9: The solution depends on external software for data transmission. The solution must not interfere with the data plane. Error handling of the data plane is handled by the external application.

The solution only modifies HTTP headers. The effective transmission of the data between the parties is not part of the authentication mesh. As such, error handling for the transmission is also out-sources to the used proxy software.

### NFR 10: Error Handling

> NFR 10: The solution handles errors in the translation and the automation engine according to the architectural description.

All parts of the authentication mesh rely on external software, with the exception of translators. As stated above, error handling for the transmission of data is not needed since this is done by a proxy (Envoy in the POC). All other components are not part of the critical path. {@sec:poc_translator} states that in the case of a timeout, error, or invalid data, the request must be blocked by the translator. Only valid requests may be let through to the destination.

## Prevent Leakage of Credentials

As stated in {@sec:deficiencies}, when applications with diverging authentication schemes communicate with eachother, they must leak credentials onto the wire. Otherwise, it would not be possible to authenticate a user in each system. The principle of zero trust shows that each application must validate the user and check the credentials that are presented.

The distributed authentication mesh eliminates the need of effective credentials in communication with the federated identity. Similar to SAML ({@sec:saml}), an encoded identity is transmitted with the request instead of user credentials such as passwords or access tokens. This identity is then translated to effective credentials in the translator and ultimatively forwarded to the target application.

## Improve Developer and User Experience

Another identified problem in {@sec:deficiencies} is the introduction of code when such a usecase arises. To enable "modern software" to talk with "legacy software" (or third-party software), most likely the modern software must implement the translation logic. This may introduce bugs and does not scale when the service landscape grows.

The proposed solution enables developers to declaratively (via configuration) transform such credentials between applications. When used on a cloud environment, the automation engine can take care of all moving parts. With the solution in place, a developer is only required to configure the application as part of the mesh and the automation engine will inject the needed proxy and translators. After that step has taken place, the application is enhanced with additional authentication schemes without implementing the effective translation by itself.
