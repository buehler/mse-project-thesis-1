+-------+------------------------------------------------------------+
| Name  |                        Description                         |
+=======+============================================================+
| REQ 1 | The translator module must be able to transform            |
|       | given credentials into the specified common language and   |
|       | the common format back into valid credentials.             |
+-------+------------------------------------------------------------+
| REQ 2 | The translator is injected as a sidecar into the           |
|       | solution. In Kubernetes this is done via an operator.      |
+-------+------------------------------------------------------------+
| REQ 3 | Beside the translator, an Envoy proxy is injected into the |
|       | service in question to handle the data flow. This          |
|       | injection is performed by the operator as well.            |
+-------+------------------------------------------------------------+
| REQ 4 | Translators do only modify HTTP headers. They do not       |
|       | interfere with the data that is transmitted. Any           |
|       | information that needs to be forwarded must reside in      |
|       | the HTTP headers.                                          |
+-------+------------------------------------------------------------+
| REQ 5 | The automation engine can decide which elements are        |
|       | relevant for the authentication mesh.                      |
+-------+------------------------------------------------------------+
| REQ 6 | The automation engine - if it exists - enhances objects    |
|       | with the proxy and translator engine.                      |
+-------+------------------------------------------------------------+

Table: Functional Requirements {#tbl:functional-requirements}
