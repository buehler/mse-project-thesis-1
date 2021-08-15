+--------+------------------------------------------------------------------+
|  Name  |                           Description                            |
+========+==================================================================+
| NFR 1  | First and foremost, the solution **must not** be less secure     |
|        | than current solutions.                                          |
+--------+------------------------------------------------------------------+
| NFR 2  | The solution must adhere to current best practices               |
|        | and security mechanisms. Furthermore, it **must** be             |
|        | implemented according to the standards of the practice           |
|        | to mitigate security issues as stated in the OWASP               |
|        | Top Ten (<https://owasp.org/www-project-top-ten>).               |
+--------+------------------------------------------------------------------+
| NFR 3  | The concept of the solution is applicable to cluster             |
|        | orchestration software other than Kubernetes. The                |
|        | architecture provides a general way of solving the               |
|        | stated problem instead of giving a proprietary solution          |
|        | for one vendor. The concept should even be realizable            |
|        | for non-orchestration platforms like a Windows operating system. |
+--------+------------------------------------------------------------------+
| NFR 4  | The translation of the credentials should not extensively        |
|        | impact the timeframe of an arbitrary request. In                 |
|        | production mode, the additional time to check and transform      |
|        | the credentials **should** not exceed 100ms.                     |
|        | This is a general recommendation and some authentication         |
|        | mechanism may exceed the stated 100ms.                           |
+--------+------------------------------------------------------------------+
| NFR 5  | The solution must be extensible with additional                  |
|        | "translators" that provide the means of transforming             |
|        | the given credentials to other target formats.                   |
+--------+------------------------------------------------------------------+
| NFR 6  | The solution may run with or without a service mesh.             |
|        | It is a goal that the solution can run without a service         |
|        | mesh to reduce the overall complexity, but if a service          |
|        | mesh is already in place, the solution must be able to           |
|        | work with the provided infrastructure.                           |
+--------+------------------------------------------------------------------+
| NFR 7  | The architecture **must** be scalable. In a cloud-native         |
|        | environment, the application that is enhanced may                |
|        | be scaled. Therefore, the solution must be able to scale         |
|        | with the application as well.                                    |
+--------+------------------------------------------------------------------+
| NFR 8  | Each translator **should** only handle one authentication scheme |
|        | to ensure separation of concerns and scalability of              |
|        | the whole solution.                                              |
+--------+------------------------------------------------------------------+
| NFR 9  | The solution depends on an external software for data            |
|        | transmission. The solution **must not** interfere with the       |
|        | data plane. Error handling of the data plane is handled by       |
|        | the external application.                                        |
+--------+------------------------------------------------------------------+
| NFR 10 | The solution handles errors in the translation and the           |
|        | automation engine according to the architectural description.    |
+--------+------------------------------------------------------------------+

Table: Non-Functional Requirements {#tbl:non-functional-requirements}
