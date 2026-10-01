# M01 - What Is Terraform?

## Learning Goals

By the end of this module, you should be able to explain:

- What Terraform is and why teams use it.
- What problems Infrastructure as Code (IaC) solves.
- The difference between declarative configuration and imperative scripts.
- Desired state, current state, and real infrastructure.
- Providers, resources, and dependencies.
- How Terraform builds and uses a dependency graph.

## What Is Terraform?

Terraform is an Infrastructure as Code tool created by HashiCorp. It lets you describe infrastructure in configuration files and then creates or changes that infrastructure through cloud and service APIs.

Instead of manually clicking through the Azure or AWS console, you write a repeatable description of the infrastructure you want. Terraform compares that description with what already exists, creates a plan, and applies only the changes that are needed.

A simplified flow is:

```text
Terraform configuration
          |
          v
terraform plan
          |
          v
Terraform compares desired state with state and real infrastructure
          |
          v
terraform apply
          |
          v
Cloud resources are created, changed, or removed
```

Terraform is commonly used to manage:

- Networks, subnets, and routing.
- Virtual machines and managed Kubernetes clusters.
- Load balancers, databases, and storage.
- DNS records and monitoring resources.
- IAM roles, policies, and security rules.
- Development, staging, and production environments.

Terraform is not an operating-system configuration tool. It can create a virtual machine, but tools such as cloud-init, Ansible, Kubernetes, or a CI/CD system may be better suited to install and configure software inside that machine.

## Why Do We Need Terraform?

Without IaC, infrastructure is often created manually:

1. An engineer clicks through a cloud console.
2. Another engineer repeats the process for staging.
3. Someone forgets one setting in production.
4. The team no longer knows exactly how the environment was built.
5. Recreating the environment becomes slow and error-prone.

Terraform solves these problems by making infrastructure:

- **Repeatable:** The same configuration can create the same type of environment again.
- **Reviewable:** Changes are stored in Git and reviewed like application code.
- **Consistent:** Development, staging, and production can follow the same patterns.
- **Automated:** CI/CD pipelines can plan and apply approved changes.
- **Auditable:** Git history shows who changed the infrastructure and why.
- **Recoverable:** Infrastructure can be rebuilt from configuration after a failure.
- **Portable:** The same Terraform workflow can manage Azure, AWS, and many other services.

Terraform does not remove the need for good design, security, testing, or monitoring. It makes the desired infrastructure explicit and automatable.

## What Problem Does Terraform Solve?

Suppose a company needs the following environment:

- A virtual network.
- A subnet inside that network.
- A web server inside the subnet.
- A security rule allowing HTTP traffic.

A manual process depends on a person remembering the correct order and settings. Terraform records the configuration and understands that the subnet depends on the network, while the virtual machine depends on the subnet.

If the environment is missing, Terraform can create it. If it already exists but differs from the configuration, Terraform can show the difference. If the configuration is unchanged, Terraform should make no changes.

Terraform is especially useful when infrastructure must be created many times, changed safely, or maintained by more than one person.

## Declarative Configuration vs Imperative Scripts

### Declarative Configuration

A declarative configuration describes **what the final result should be**. You do not usually write every command Terraform must execute. Terraform decides the required operations.

```hcl
resource "azurerm_resource_group" "app" {
  name     = "rg-example-app"
  location = "East US"
}
```

This says:

> There should be an Azure resource group named `rg-example-app` in `East US`.

Terraform decides whether it needs to create, update, or leave the resource alone.

### Imperative Script

An imperative script describes **the steps to execute** and their order.

```bash
az group create \
  --name rg-example-app \
  --location eastus
```

An imperative script tells the system to run a particular command. The script author is responsible for handling questions such as:

- Does the resource already exist?
- Should it be updated or recreated?
- What happens if the command fails halfway through?
- Which command should run first?
- How should the existing environment be inspected?

### Side-by-Side Comparison

| Question | Declarative Terraform | Imperative script |
| --- | --- | --- |
| Main idea | Describe the desired result | Describe the steps |
| Who decides the steps? | Terraform | The script author |
| Repeated execution | Usually converges on the same result | May repeat commands or need custom checks |
| Dependency handling | Terraform builds a graph | The author usually orders commands |
| Change detection | Terraform compares configuration and state | The author must implement checks |
| Review | Configuration and plan can be reviewed | Commands can be reviewed, but state handling is custom |

Imperative scripts still have a place. They are useful for one-time tasks, migrations, and actions that are naturally procedural. Terraform is best when the goal is to manage infrastructure as a durable desired state.

## Desired State, Current State, and Real Infrastructure

These three ideas are easy to mix up.

### Desired State

Desired state is what the Terraform configuration says should exist.

```hcl
resource "azurerm_resource_group" "app" {
  name     = "rg-example-app"
  location = "East US"
}
```

The desired state includes the resource type, name, location, tags, size, networking, and other declared settings.

### Current State

Current state is Terraform's record of the infrastructure it manages. It is normally stored in a state file or a remote backend.

The state records facts such as:

- Which real resource belongs to `azurerm_resource_group.app`.
- The cloud resource ID.
- Important attributes returned by the provider.
- Relationships between managed resources.

State is not simply a copy of the `.tf` files. It is Terraform's mapping between configuration addresses and real resource IDs.

### Real Infrastructure

Real infrastructure is what currently exists in Azure, AWS, or another service. It can be changed by:

- Terraform.
- A cloud console.
- Another automation tool.
- A different team.
- An accidental manual change.

The real infrastructure can drift away from both the configuration and the state record.

### How Terraform Compares Them

A simplified model is:

```text
Desired configuration + Terraform state + real infrastructure
                         |
                         v
                    terraform plan
                         |
                         v
             Proposed create, update, or destroy actions
```

Example:

| Situation | Result of `terraform plan` |
| --- | --- |
| Configuration, state, and real infrastructure agree | No changes |
| Configuration asks for a new resource | Plan to create it |
| Configuration changes a resource property | Plan to update or replace it |
| Someone changed a managed resource in the console | Plan may repair the drift |
| Someone deleted a managed resource outside Terraform | Plan may recreate it |
| A resource exists but is not in state | Terraform does not automatically manage it; import may be needed |

Terraform normally refreshes information from the provider during planning. The exact behavior depends on the Terraform version, provider, and command options, but the important idea is that Terraform uses state and provider data to reason about the difference between the desired and actual environments.

## Providers

A provider is a Terraform plugin that knows how to communicate with an external API.

Examples include:

- `azurerm` for Azure.
- `aws` for Amazon Web Services.
- `google` for Google Cloud.
- `kubernetes` for Kubernetes.
- `github` for GitHub.
- `random` for generated values used by Terraform configurations.

A provider supplies resource types and data source types. Terraform itself does not contain the implementation for every cloud API; the provider performs that service-specific work.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Important provider concepts:

- **Source:** Where Terraform obtains the provider, such as `hashicorp/azurerm`.
- **Version constraint:** Which provider versions are acceptable.
- **Provider configuration:** Settings such as a region, subscription, or features.
- **Authentication:** Usually supplied through environment variables, CLI login, workload identity, or another secure mechanism.

Do not place cloud passwords or secret keys directly in a Terraform file. Use the cloud CLI, environment variables, a CI/CD identity, or a secret manager.

## Resources

A resource represents an object that Terraform can create, update, or delete.

The general syntax is:

```hcl
resource "<provider_resource_type>" "<local_name>" {
  # arguments
}
```

Example:

```hcl
resource "azurerm_resource_group" "app" {
  name     = "rg-example-app"
  location = "East US"

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

This resource has two names:

- `azurerm_resource_group` is the provider resource type.
- `app` is the local Terraform name.

Together they form the Terraform address:

```text
azurerm_resource_group.app
```

The local name is not necessarily the Azure name. The Azure name is the value of the `name` argument.

Resources are the main way Terraform manages infrastructure. A resource can be created, changed, replaced, or destroyed as the configuration changes.

## Dependencies and the Terraform Graph

Infrastructure has relationships. A subnet cannot be created until its virtual network exists. A virtual machine cannot use a subnet until that subnet exists. Terraform represents these relationships as a dependency graph.

Consider this example:

```hcl
resource "azurerm_resource_group" "app" {
  name     = "rg-example-app"
  location = "East US"
}

resource "azurerm_virtual_network" "app" {
  name                = "vnet-example-app"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

The references create these dependencies:

```text
azurerm_resource_group.app
              |
              v
azurerm_virtual_network.app
              |
              v
azurerm_subnet.web
```

Terraform can create the resource group first, then the virtual network, then the subnet. During deletion, it generally works in the reverse order.

### Implicit Dependencies

An implicit dependency is created when one resource references another resource.

```hcl
resource "azurerm_virtual_network" "app" {
  resource_group_name = azurerm_resource_group.app.name
  # ...
}
```

Because the virtual network uses `azurerm_resource_group.app.name`, Terraform knows that the resource group must exist first.

### Explicit Dependencies

Sometimes a dependency exists but is not visible in an attribute reference. In that case, use `depends_on` carefully.

```hcl
resource "azurerm_role_assignment" "app" {
  # role assignment arguments

  depends_on = [azurerm_resource_group.app]
}
```

Prefer implicit dependencies when possible. They are more precise and easier to understand. Use `depends_on` only when Terraform cannot infer a real dependency from the configuration.

### Viewing the Graph

After initializing a configuration, you can ask Terraform to output its dependency graph:

```bash
terraform graph
```

The output is commonly written in DOT format. Graphviz can render it as an image:

```bash
terraform graph | dot -Tpng > terraform-graph.png
```

The graph is useful when debugging unexpected ordering, dependency cycles, or a resource that Terraform wants to replace.

## A Complete Small Example

The following example declares a provider, a resource group, a virtual network, and a subnet. It shows how resource references connect the infrastructure.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "app" {
  name     = "rg-terraform-learning"
  location = "East US"
}

resource "azurerm_virtual_network" "app" {
  name                = "vnet-terraform-learning"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.10.1.0/24"]
}
```

The normal workflow is:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

`terraform plan` is the safety checkpoint. Read it before applying. It should clearly show what Terraform will create, change, or destroy.

This example can create billable Azure resources. Use a test subscription, understand the costs, and destroy the resources when finished:

```bash
terraform destroy
```

## Simple Real-World Example

Imagine ordering furniture for a new office.

### Imperative Approach

You give someone a step-by-step list:

1. Buy a desk.
2. Buy a chair.
3. Assemble the desk.
4. Put the chair beside the desk.
5. If the desk already exists, check whether it is the correct size.

The person must handle the order and all exceptions.

### Declarative Approach

You describe the desired office:

> The office should contain one assembled desk, one chair, and a lamp. The chair should be beside the desk.

The person checks the current room, identifies what is missing or incorrect, and performs only the required work.

The mapping to Terraform is:

| Office example | Terraform idea |
| --- | --- |
| Desired office design | Terraform configuration |
| Inventory list | Terraform state |
| Actual room | Real infrastructure |
| Desk or chair | Resource |
| Furniture supplier | Provider |
| Desk must exist before the chair is positioned | Dependency graph |
| Difference between design and room | Terraform plan |

Terraform is the declarative version of managing the office. You describe what the room should contain, and Terraform calculates how to make reality match that description.

## Key Takeaways

- Terraform manages infrastructure through declarative configuration.
- A provider connects Terraform to a cloud or external service.
- A resource represents an object Terraform can manage.
- Desired state comes from configuration.
- Current state is Terraform's record of managed resources.
- Real infrastructure is what actually exists in the provider.
- Terraform compares these sources of information and creates a plan.
- References between resources create a dependency graph.
- Terraform manages infrastructure; other tools may configure software inside it.
- Always inspect `terraform plan` before `terraform apply`.

## Practice Questions

1. What is the difference between a Terraform configuration and Terraform state?
2. Why is a Terraform configuration called declarative?
3. What is the role of a provider?
4. What is the difference between a resource type and a resource local name?
5. Why must a subnet depend on a virtual network?
6. What is an implicit dependency?
7. When might `depends_on` be necessary?
8. What might happen if someone changes a managed resource manually in the cloud console?
9. Which tool would you use to configure software inside a virtual machine?
10. Why should you review `terraform plan` before applying changes?
