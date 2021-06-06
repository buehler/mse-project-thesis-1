# Conclusion

This report shows a potential solution to the problem of dynamic credential transformation in systems with diverging authentication mechanisms. In {@sec:introduction}, a brief overview states the problem and describes the goal of the project.

{@sec:definitions} defines the scope of the project and explains various technologies and terms like "Kubernetes", "Operator Pattern", and "Sidecar Pattern". Furthermore, {@sec:definitions} introduces vital information about authentication, authorization, and security standards required for the general understanding of this report.

{@sec:state_of_the_art} then gives an overview of the current state of the art and the problems in the practice. Several problems, like the maintainability of implementing multiple authentication schemes and the leakage of credentials in an environment, were identified.

To address the deficiencies, {@sec:solution} proposes a conceptional architecture and a platform-specific example (on Kubernetes) of the architecture to solve the issues stated in {@sec:state_of_the_art}. With a networking component that intercepts communication with an application, the "Distributed Authentication Mesh" is able to transform credentials (like an access token) of a user to a specific identity. This identity is then translated to other authentication schemes (for example to Basic Authentication credentials) on the receiving side. The proof of concept in {@sec:poc} shows that it is possible to modify HTTP headers in-flight and therefore the concept of the architecture is generally possible.

{@sec:evaluation} checks if the given requirements and goals/non-goals in {@tbl:non-functional-requirements} can be achieved with the proposed architecture. Additionally, the evaluation shows that the solution is able to enhance general security by preventing the leakage of credentials into the communication. Furthermore, the developer experience gets better since no additional code must be created to support various authentication mechanisms.

As an additional delivery, this project provides learning material for the topic of "Kubernetes Operators and how to create them". This material may be used to introduce people to the operator pattern and helps to create a custom operator with a SDK.

To improve the current state of the project, further projects target a production-ready state of the solution. The goal is to provide a federated authentication with secured communication without leakage of credentials out of the trust zone.

To achieve this goal, the common format (DSL) for the transmitted identity must be evaluated and defined. Furthermore, it is required to create definitions for the configuration of the system. With the implementation of a production-ready system in Kubernetes, various usecases can be covered. As an example, in the finance sector, banking APIs tend to use variing authentication schemes and do not wish to change their applications. The authentication mesh improves this situation by covering the dynamic transformation of credentials to the respective format.

Additionally, this system could be implemented as an application that runs directly on an operating system to provide a federated identity into a company network. It negates the need of implementing technologies like SAML in each application that is access in this company network.
