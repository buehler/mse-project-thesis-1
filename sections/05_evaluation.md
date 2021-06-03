# Evaluation

This section evaluates the concept and the architecture of {@sec:solution}. The main goal is to show that the proposed solution can improve the current situation and does not introduce security issues when used. Since the architecture is only conceptional, the evaluation is done in a theroretical manner.

## The Architecture versus the Requirements

To show that the architecture of the distributed authentication mesh does improve the developer experience as well as the current situation with legacy or third-party software, we compare the architecture against the non functional requirements in {@tbl:non-functional-requirements}.

### NFR 1: Improve Security

> NFR 1: First and foremost, the solution **must not** be less secure than current solutions.

Currently, without the distributed authentication mesh, credentials like access tokens or basic authentication credentials are transmitted in the HTTP headers. This is a well-known way of authorizing requests [@RFC1945]. If the current standard is viewed as "secure" - not judging by the authorization scheme - then the mesh is secure as well. It even improves the security by hiding the originally used credentials. This may prevent man in the middle attacks and leakage of credentials.

## Prevent Leakage of Credentials

## Improve Developer and User Experience
