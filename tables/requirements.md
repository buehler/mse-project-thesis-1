+-------+---------------------------------------------------------------+
| Name  |                          Description                          |
+=======+===============================================================+
| REQ 1 | The translator module must be able to transform               |
|       | given credentials into the specified common language and      |
|       | the common format back into valid credentials.                |
+-------+---------------------------------------------------------------+
| REQ 2 | The translator handles errors if they occur.                  |
|       | When an unrecoverable error happens, the request is rejected. |
+-------+---------------------------------------------------------------+
| REQ 3 | A proxy is deployed to intercept communication with the       |
|       | service in question to handle the data flow.                  |
+-------+---------------------------------------------------------------+
| REQ 4 | Translators do only modify HTTP headers. They must not        |
|       | interfere with the data that is transmitted.                  |
+-------+---------------------------------------------------------------+
| REQ 5 | The automation engine decides which elements are              |
|       | relevant for the authentication mesh.                         |
+-------+---------------------------------------------------------------+
| REQ 6 | The automation engine — if it exists — enhances objects       |
|       | with the proxy and translator engine.                         |
+-------+---------------------------------------------------------------+

Table: Functional Requirements {#tbl:functional-requirements}
