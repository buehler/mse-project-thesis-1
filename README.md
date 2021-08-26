# Distributed Authentication Mesh

> A Concept for Declarative Ad Hoc Conversion of Credentials

Spring Semester 2021\
University of Applied Science of Eastern Switzerland (OST)

## Abstract

As more and more applications run in containerized cloud environments, securing their architectures against attackers is an important concern. Applications defend themselves against intrusion with various authentication mechanisms such as OpenID Connect. However, legacy applications that are not updated nor rewritten tend not to support modern security standards. Enabling applications to communicate with legacy (or third-party) software often requires to introduce code changes to the modern apps.

To eliminate leaking credentials (such as access tokens) and to reduce the risk of bugs, this project targets the dynamic conversion of a user identity. This identity is used to authenticate the user instead of the original credentials. This project provides the conceptional idea and the architecture, as well as a platform specific example of such a solution. A Proof of Concept answers relevant questions for the realization of such a framework. The evaluation then shows that the proposed solution is as secure as the current state of the art and validates the architecture against the goals. The conclusion provides information about the project, possible use cases, and the goals of follow-up projects.

## Thanks

I would like to express my appreciation to [Dr. Olaf Zimmermann](https://ozimmer.ch/about/) for guiding and reviewing this work. Furthermore, special thanks to [Florian Forster](https://github.com/fforootd), who challenged the results of this project from a practical perspective.

## Full Report

To view the full project report please visit:
[Distributed Authentication Mesh](https://buehler.github.io/mse-project-thesis-1/report.pdf)
