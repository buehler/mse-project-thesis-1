# Appendix A: Common Kubernetes Terminology {.unnumbered}

In {@tbl:kubernetes_terminology}, we state the most common Kubernetes terminology. The table provides a list of terms that is used to explain concepts like the operator pattern.

```{.include}
tables/kubernetes_terminology.md
```

# Appendix B: Teaching Material for Kubernetes Operators {#sec:teaching-material .unnumbered}

## Motivation {.unnumbered}

The usefulness of Kubernetes Operators shows as there exists a variety of them. For example, the Prometheus Operator^[<https://github.com/prometheus-operator/prometheus-operator>] which manages instances of Prometheus^[<https://prometheus.io/>] in Kubernetes. A non-exhaustive list of operators can be found on [https://operatorhub.io](https://operatorhub.io/). An operator is not required to perform only one task.

Since operators are an elegant tool to extend the capabilities of Kubernetes, developers may want to know how to create a custom operator. This material gives an overview of the operator pattern and a description of how operators work. As an exercise, a custom operator must be written with the help of an SDK. The solution to the custom operator is implemented with C\# and the .NET operator SDK "KubeOps"^[<https://github.com/buehler/dotnet-operator-sdk>].

## Learning Objectives {.unnumbered}

The operator pattern is well defined [@dobies:KubernetesOperators]. To be able to implement a custom operator, the building blocks and concepts of the internal elements of an operator must be known. An SDK helps to create an operator, but when the operator gets more complex, it may be vital to know how operators work. Therefore, this material shows how an operator works and how one can be built.

To summarize the learning objectives:

- One can explain the operator pattern with own words
- One can explain the parts of an operator with own words
- One can build a custom operator with an SDK

## Kubernetes Operators and their Use {.unnumbered}

### What is an Operator? {.unnumbered}

An operator in Kubernetes is an extension to the Kubernetes API itself. A custom operator typically manages the whole lifecycle of an application [@dobies:KubernetesOperators].

![Kubernetes Operator Reconciliation Loop](images/teaching_material/reconciliation_loop.png){#fig:teach_op_loop}

To describe the "reconciliation loop" of an operator, we have a look at {@fig:teach_op_loop}. The reconciliation loop is the constant observation of the current state. When the current state diverges from the desired state, adjustments must be made to achieve the current state again. This loop is used by the Kubernetes API itself. As an example, if a user creates a deployment in Kubernetes, the API stores the deployment as the new desired state. The reconciliation loop checks if the deployment exists, and if it does not, it creates the deployment to reach the desired state.

![Kubernetes Operator Pattern](images/teaching_material/operator_pattern.png){#fig:teach_op_pattern}

The operator pattern uses the reconciliation loop to manage a custom application or a custom use case. The pattern is shown in {@fig:teach_op_pattern}. When a user modifies resources (be it custom resources or predefined ones), the API stores the resources as the new desired state. The operator gets notified by the API and can adjust elements in Kubernetes.

The operator pattern can be used to manage whole applications, for example Prometheus or PostgreSQL databases. Another use case of an operator could include injecting logging collectors into each deployment in the cloud environment.

### How do Operators work? {.unnumbered}

The following objects exist in or around an operator:

- **Watcher**^[<https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes>]: The operator registers one or multiple watchers with the Kubernetes API. This enables the operator to receive events when a watched resource gets modified. A watcher can be namespaced or global and can watch one type of resource (e.g. Depoyments, Services, or a custom resource).
- **Event**[<https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes>]: Events are the notification of the Kubernetes API that a watcher receives. There exist three relevant types of events:
  - _Added_: When a resource gets added to the watcher. This event is fired for each resource of the watched type when the watcher is registered.
  - _Modified_: When a resource that is already being watched gets modified.
  - _Deleted_: When a watched resource is removed from Kubernetes and the watcher.
- **Custom Resource Definition**^[<https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/>]: A CRD is the definition of a custom resource in Kubernetes. There exist resource definitions for all standard resources like deployments and services. A CRD enables developers to create custom resources which can be reconciled by an operator.
- **Controller**^[<https://kubernetes.io/docs/concepts/architecture/controller/>]: Controllers are elements in an operator that reconcile a specific CRD/resource. An operator can contain multiple controllers and therefore manage multiple CRDs. A controller typically contains application logic to react to the events of the Kubernetes API.
- **Finalizer**^[<https://kubernetes.io/blog/2021/05/14/using-finalizers-to-control-deletion/>]: A finalizer is a part of an operator that enables asynchronous deletion processes in Kubernetes. When a resource contains finalizers in its metadata, the API will mark the resource as in pending deletion. An operator may react to this state and can perform additional tasks, such as deleting a database or external resources. The operator must then remove its finalizer entry. When all finalizers are removed, the resource is deleted. Otherwise, it will remain in the pending deletion state.
- **Mutation Webhook**^[<https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/>]: A mutator (or mutation webhook) is an HTTP endpoint of an operator. The endpoint will be called whenever a watched resource type is created/updated/deleted. A mutator may return an empty response to acknowledge the creation/modification/deletion of the resource or it can patch the resource before the effective action is executed. The patch must be in the form of a JSON Patch, as defined in **RFC6902** [@RFC6902]. As an example, one could create a profanity filter and remove "bad" usernames from resources. Mutators are **called in series** by the Kubernetes API.
- **Validation Webhook**^[<https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/>]: In contrast to a mutation webhook, a validator (or validation webhook) may only accept or reject a resource. If multiple validators are registered for a certain type, they will be **called in parallel** by the Kubernetes API.

![Kubernetes Operator Workflow](diagrams/sequences/kubernetes-operator-process.puml){#fig:teach_kubernetes_operator_workflow}

To specify the general workflow in {@fig:teach_op_pattern} in more detail, {@fig:teach_kubernetes_operator_workflow} depicts the concrete sequence of a reconciliation loop. An important note on admission webhooks (mutators/validators): if the operator does not respond within ten seconds, the API will abort the creation/modification/deletion of the resource. This could lead to deadlocks when the operator crashes or is not able to respond to the webhooks.

### What is an Operator SDK? {.unnumbered}

To help developers create custom operators, SDKs provide aid to perform the Kubernetes specific tasks. Depending on the SDK, several technical elements are abstracted like registering and error handling of the wachers. A non-exhaustive list of SDKs includes:

- KUDO^[<https://kudo.dev/>]: A declarative operator SDK that creates operators based on declarative descriptions.
- kubebuilder^[<https://book.kubebuilder.io/>]: A GoLang based SDK that allows creating controllers and validation webhooks.
- OPERATOR SDK^[<https://operatorframework.io/>]: A multi language SDK that allows GoLang based operators, Helm based operators, or Ansible based operators by using hooks to execute scripts.
- Shell-operator^[<https://github.com/flant/shell-operator>]: Event driven script runner for Kubernetes. Operator SDK for shell scripts.
- Kopf^[<https://kopf.readthedocs.io/en/stable/>]: "Kubernetes Operator Framework (Kopf)", is a Python based SDK with an immense feature set.
- KubeOps^[<https://buehler.github.io/dotnet-operator-sdk/>]: A .NET operator SDK based on the principles of ASP.NET applications. Operators can be created with C\# or F\#.

## Exercise: Create a Custom Operator with an SDK {.unnumbered}

### TL;DR {.unnumbered}

1. Create an empty operator with an SDK of your choice and run it.
2. Create a CRD for a "WeatherLocation" and for "WeatherData".
3. Create the controllers for the CRDs and run/deploy the operator. The use case is: The user can create a WeatherLocation object and the operator should then fetch any weather data API and create WeatherData objects for each hour. When a specific amount of WeatherData elements are created, old objects must be deleted.

The examples and solutions are created with KubeOps in C\#. When code is shown, the required "usings" are omitted. A possible solution can be found on GitHub: <https://github.com/buehler/kubernetes-operator-exercise>.

### Create and Run an empty Operator {.unnumbered}

Select an SDK and create an empty operator and run it against a Kubernetes environment. One can use any Kubernetes environments, but it is advised to use a local instance like Docker Desktop with Kubernetes or [minikube](https://minikube.sigs.k8s.io/docs/start/).

#### Solution {.unnumbered}

KubeOps provides templates to create an operator.

1. Install the templates: `dotnet new -i KubeOps.Templates::*`
2. Create the empty operator: `dotnet new operator-empty -n WeatherOperator -o ./weather-operator`
3. Run the empty operator against the Kubernetes environment

You should see the following log output:

```
info: KubeOps.Operator.Leadership.LeaderElector[0]
      Startup Leader Elector for operator "weatheroperator".
info: KubeOps.Operator.Leadership.LeaderElector[0]
      There was no lease for operator "weatheroperator".
      Creating one and electing "xxx" as leader.
info: Microsoft.Hosting.Lifetime[0]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[0]
      Now listening on: https://localhost:5001
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
```

The empty operator in C\# only registers the operator logic with ASP.NET and starts the webserver. The minimal config required to run consists of:

`Program.cs`:

```csharp
static IHostBuilder CreateHostBuilder(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .ConfigureWebHostDefaults(webBuilder =>
        {
            webBuilder.UseStartup<Startup>();
        });

await CreateHostBuilder(args).Build().RunOperatorAsync(args);
```

`Startup.cs`:

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddKubernetesOperator();
    }

    public void Configure(IApplicationBuilder app)
    {
        app.UseKubernetesOperator();
    }
}
```

### Create the Custom Resource Definition {.unnumbered}

Create the required objects in the operator and create the CRD for Kubernetes. The CRD is the element that gets installed in the API of Kubernetes. The following two objects must be created:

- **WeatherLocation**: Object that contains the required data to query a weather API for weather data. As an example, if the [OpenWeather API](https://openweathermap.org/api) is used, the object should include latitude and longitude to identify the point of interest. Depending on the API you intent to use, you may need to add other fields.
- **WeatherData**: This object shall not be created by a user. It contains the "result" for a weather query. It must be linked to a WeatherLocation and should be cleaned up after 24 hours.

#### Solution {.unnumbered}

`WeatherLocation`: To use the OpenWeather API, we only need the latitude and the longitude to create a weather call.

```csharp
public class V1WeatherLocationSpec
{
    public double Latitude { get; set; }

    public double Longitude { get; set; }
}

public class V1WeatherLocationStatus
{
    public DateTime? LastCheck { get; set; }

    public string? Error { get; set; }
}

[KubernetesEntity(
    ApiVersion = "v1",
    Group = "kubernetes.dev",
    Kind = "WeatherLocation")]
[EntityScope(EntityScope.Cluster)]
public class V1WeatherLocation : CustomKubernetesEntity
    <V1WeatherLocationSpec, V1WeatherLocationStatus>
{
}
```

`WeatherData`: This object should be created by the operator during runtime. It contains several elements of the weather call. The weather data object must be linked to a weather location.

```csharp
public class V1WeatherDataSpec
{
    [AdditionalPrinterColumn]
    public string MainWeather { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    [AdditionalPrinterColumn]
    public double Temperature { get; set; }

    public DateTime Sunrise { get; set; }

    public DateTime Sunset { get; set; }
}

[KubernetesEntity(
    ApiVersion = "v1",
    Group = "kubernetes.dev",
    Kind = "WeatherData")]
[EntityScope(EntityScope.Cluster)]
public class V1WeatherData : CustomKubernetesEntity<V1WeatherDataSpec>
{
}
```

KubeOps generates the CRDs found in the repository at <https://github.com/buehler/kubernetes-operator-exercise/tree/main/config/crds>.

These CRDs may now be installed into Kubernetes with `kubectl apply`.

### Reconcile the Custom Resource {.unnumbered}

As the operator base and the CRDs are prepared, you are now to build the operator logic. The operator must fulfill the following requirements:

- A weather API call is executed each hour for a given weather location object
- The result of the API call is stored in Kubernetes as weather data object and linked to the weather location (owner reference)
- While reconciling, the operator deletes old weather data objects (keep the last twelfe)
- A validator checks if the longitude and latitude values are possible and denies the creation of the object if they are not within the boundaries
- A validator checks if a weather data object contains an owner reference

#### Solution {.unnumbered}

Since it is not feasible to print the whole source code in this exercise, please find a possible solution on GitHub: <https://github.com/buehler/kubernetes-operator-exercise>.
