---
Title: AI Runtime Security deployment templates
---

## Detailed Architecture

### Centralized Design

This design supports interconnecting a large number of VPCs, with a scalable solution to secure outbound, inbound, and east-west traffic flows using a transit gateway to connect the VPCs. The centralized design model offers the benefits of a highly scalable design for multiple VPCs connecting to a central hub for inbound, outbound, and VPC-to-VPC traffic control and visibility. In the Centralized design model, you segment application resources across multiple VPCs that connect in a hub-and-spoke topology. The hub of the topology, or transit gateway, is the central point of connectivity between VPCs and Prisma Access or enterprise network resources attached through a VPN or AWS Direct Connect. This model has a dedicated VPC for security services where you deploy AI Runtime Security for traffic inspection and control. The security VPC does not contain any application resources. The security VPC centralizes resources that multiple workloads can share. The TGW ensures that all spoke-to-spoke and spoke-to-enterprise traffic transits the AI Runtime Security.

Combined Model

Inbound traffic originates outside your VPCs and is destined to applications or services hosted within your VPCs, such as web or application servers. The combined model implements inbound security by using the AI FW and Gateway Load Balancer (GWLB) in a Security VPC, with distributed GWLB endpoints in the application VPCs. Unlike with outbound traffic, this design option does not use the transit gateway for traffic forwarding between the security VPC and the application VPCs.

### Autoscaling

The common firewall option with autoscaling leverages a single set autoscale group of AI Runtime Security. It can scale horizontally based on configurable metrics.

The topology is split into two sets of Templates:

- Security Project Templates
- Application Project Templates

#### Security Project templates

The firewalls or the security stack has its own terraform template available for download. This includes the resources needed to firewall User to App, App to Model, App to App and App to Internet traffic. With default variable values the topology consists of following:

- Security VPC
- Gateway Load Balancer
- Transit Gateway and Transit Gateway Attachment
- AI-FW
- Route Tables

#### Application Project templates

The application VPCs are peered to the hub VPC and there is a separate terraform that is available for download. This has all the peering constructs as well as route table to route all the traffic through the GWLB in the security VPC of the firewall.

## Prerequisites

The following steps should be followed before deploying the Terraform code presented here.

## Usage

### Go to `security_project` folder

The templates are for AI security VPC creation.

    1. Copy `example.tfvars` into `terraform.tfvars`
    2. Review `terraform.tfvars` file, especially look for comment #REPLACE-WITH
    3. Initialize Terraform: `terraform init`
    4. Prepare plan: `terraform plan`
    5. Deploy infrastructure: `terraform apply -auto-approve`
    6. Destroy infrastructure if needed: `terraform destroy -auto-approve`

**Please keep your `terraform.tfstate` safely. Such as store tfstate to the [cloud storage](https://cloud.google.com/docs/terraform/resource-management/store-state).

### Go to `application_project`

The templates are for peering the application VPCs.

    1. Copy `example.tfvars` into `terraform.tfvars`
    2. Review `terraform.tfvars` file.
    3. Initialize Terraform: `terraform init`
    4. Prepare plan: `terraform plan`
    5. Deploy infrastructure: `terraform apply -auto-approve`
    6. Please check the outputs for referring the route tables, such as: TBD

**Please keep your `terraform.tfstate` safely. Such as store tfstate to the [cloud storage](https://cloud.google.com/docs/terraform/resource-management/store-state).

### Go to `helm`

Please execute the command:

    ```bash

    helm install `<RELEASE_NAME: the name you want>`

    ```

## Debugging Terraform

Terraform has detailed logs that you can enable by setting the TF_LOG environment variable to any value. Enabling this setting causes detailed logs to appear on stderr.
You can set TF_LOG to one of the log levels (in order of decreasing verbosity) TRACE, DEBUG, INFO, WARN or ERROR to change the verbosity of the logs.
Setting TF_LOG to JSON outputs logs at the TRACE level or higher, and uses a parseable JSON encoding as the formatting.
Logging can be enabled separately for Terraform itself and the provider plugins using the TF_LOG_CORE or TF_LOG_PROVIDER environment variables.
These take the same level arguments as TF_LOG, but only activate a subset of the logs.
To persist logged output you can set TF_LOG_PATH in order to force the log to always be appended to a specific file when logging is enabled.
Note that even when TF_LOG_PATH is set, TF_LOG must be set in order for any logging to be enabled.
If you find a bug with Terraform, please include the detailed log by using a service such as gist.

Reference: <https://developer.hashicorp.com/terraform/internals/debugging>

### Destory

- Please rollback the route tables you have changed.
- go to `helm`, and execute `helm uninstall $RELEASE_NAME`
- go to `application_project`, and execute `terraform plan -destroy` to review the destroying list, and then execute `terraform destroy -auto-approve`
- go to `security_project`, and execute `terraform destroy -auto-approve`
