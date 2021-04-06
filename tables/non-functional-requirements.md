+-------+--------------------------------------------------------------+
| Name  |                         Description                          |
+=======+==============================================================+
| NFR 1 | First and foremost, the solution **must not** be less secure |
|       | than current solutions.                                      |
+-------+--------------------------------------------------------------+
| NFR 2 | The solution must adhere to current best practices           |
|       | and security mechanisms. Furthermore, it **must** be         |
|       | implemented with security issues as stated in the OWASP      |
|       | Top Ten^[<https://owasp.org/www-project-top-ten>] in mind.   |
+-------+--------------------------------------------------------------+
| NFR 3 | The concept of the solution is applicable to cluster         |
|       | orchestration software other than Kubernetes. The            |
|       | architecture provides a general way of solving the           |
|       | stated problem instead of giving a proprietary solution      |
|       | for one vendor.                                              |
+-------+--------------------------------------------------------------+
| NFR 4 | The translation of the credentials should not extensively    |
|       | impact the timeframe of an arbitrary request. In             |
|       | production mode, the additional time to check and transform  |
|       | the credentials should not extend 100ms.                     |
+-------+--------------------------------------------------------------+
| NFR 5 | The solution is modular. It can be extended with additional  |
|       | "translators" which provide the means of transforming        |
|       | the given credentials to other target formats.               |
+-------+--------------------------------------------------------------+
| NFR 6 | The solution may run with or without a service mesh.         |
|       | It is a goal that the solution can run without a service     |
|       | mesh to reduce the overall complexity, but if a service      |
|       | mesh is already in place, the solution must be able to       |
|       | work with the provided elements.                             |
+-------+--------------------------------------------------------------+
| NFR 7 | The architecture must be scaleable. The provided software |
|       | must be able to scale according to the business needs |
|       | of the overall system. |
+-------+--------------------------------------------------------------+
| NFR 8 | Each translator should only handle one authentication scheme |
|       | to ensure separation of concerns and scalability of |
|       | the whole solution. |
|       |  |
|       |  |
|       |  |
+-------+--------------------------------------------------------------+
| NFR 9 | The solution  |
|       |  |
|       |  |
|       |  |
|       |  |
|       |  |
+-------+--------------------------------------------------------------+

Table: Non-Functional Requirements {#tbl:non-functional-requirements}
