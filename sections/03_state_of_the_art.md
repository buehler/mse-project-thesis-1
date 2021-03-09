# State of the Art, the Practice and Deficiencies

This section gives an overview over the current state of the
art as well as the deficiencies according to the author.
Following the description of the current situation, a
definition of the should situation gives an overview of
the purposed solution.

- Describe the IS situation.
- Describe the SHOULD situation.
- describe service mesh (image from referecne could be used)

Test:

```plantuml
@startuml
!include https://raw.githubusercontent.com/bschwarz/puml-themes/master/themes/cerulean-outline/puml-theme-cerulean-outline.puml

actor Client as c
participant IAM as i
participant "Service A" as a
participant "Service B" as b

c -> i : Authenticate with OIDC
i --> c : Return Credentials
c -> a : Call Service with OIDC
a -> a : Transform Credentials to Basic
a -> b : Call with Basic Credentials
@enduml
```
