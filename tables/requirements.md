+-------+--------------------------------------------------------------+
| Name  |                         Description                          |
+=======+==============================================================+
| REQ 1 | The translator module must be able to transform |
|       | given credentials into the specified common language and |
|       | the common format back into valid credentials. |
+-------+--------------------------------------------------------------+
| REQ 2 | The translator is injected as a sidecar into the |
|       | solution. In Kubernetes this is done via an operator. |
+-------+--------------------------------------------------------------+
| REQ 3 | Beside the translator, an Envoy proxy is injected to the |
|       | service inquestion to handle the data flow. This  |
|       | injection is also performed by the operator. |
+-------+--------------------------------------------------------------+
| REQ 4 | Translators do only modify HTTP headers, they do not |
|       | interfere with the data that is transmitted. Any |
|       | information that needs to be forwarded must be within |
|       | the HTTP headers. |
+-------+--------------------------------------------------------------+
| REQ 5 |  |
|       |  |
|       |  |
|       |  |
|       |  |
|       |  |
|       |  |
+-------+--------------------------------------------------------------+
| REQ 6 |  |
|       |  |
|       |  |
|       |  |
|       |  |
|       |  |
|       |  |
+-------+--------------------------------------------------------------+

Table: Functional Requirements {#tbl:functional-requirements}
