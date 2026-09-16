<div align="center">

# BLACKSITE Architecture

### Private AWS Administration Without Public Network Exposure

**VPC • EC2 • IAM • S3 • Systems Manager • PrivateLink • CloudTrail**

</div>

---

## Architecture Overview

BLACKSITE was designed around one primary constraint:

> **The EC2 workload should remain privately addressed and directly unreachable from the public internet while still supporting secure administration, scoped AWS service access, and audit visibility.**

The environment therefore avoids a public IPv4 address, Internet Gateway, NAT Gateway, SSH key pair, and inbound administrative ports.

Instead, administration and AWS service access occur through private AWS connectivity and IAM-based authorization.

---

## Network Architecture

```mermaid
flowchart TD
    Admin["Administrator<br/>AWS Management Console"]

    subgraph AWS["AWS Account"]

        SSM["AWS Systems Manager<br/>Session Manager"]

        subgraph VPC["BLACKSITE VPC<br/>10.20.0.0/16"]

            subgraph PrivateSubnet["Private Subnet<br/>10.20.1.0/24"]

                EC2["Amazon Linux EC2<br/>No Public IPv4<br/>No Inbound Rules<br/>IMDSv2 Required"]

                SSMEP["SSM Interface Endpoint<br/>HTTPS 443"]

                MSGEP["SSM Messages Interface Endpoint<br/>HTTPS 443"]

            end

            S3EP["S3 Gateway Endpoint"]

        end

        S3["Private S3 Bucket<br/>allowed/<br/>restricted/"]

        IAM["BlacksiteEC2Role<br/>Least-Privilege IAM"]

        CT["CloudTrail<br/>Event History"]

    end

    Admin -->|Starts Session| SSM

    EC2 -->|SSM Agent HTTPS 443| SSMEP
    EC2 -->|Session Channel HTTPS 443| MSGEP

    SSMEP --> SSM
    MSGEP --> SSM

    IAM -->|Temporary Credentials| EC2

    EC2 -->|Private S3 Traffic| S3EP
    S3EP --> S3

    Admin -->|Management API Activity| CT
```

The EC2 instance initiates outbound HTTPS connections to the Systems Manager interface endpoints. AWS does not initiate an inbound administrative connection to the instance.

This allows the workload to maintain **zero inbound security-group rules** while still supporting Session Manager administration.

---

## Network Boundary

The BLACKSITE workload was deployed inside:

| Component | Configuration |
|---|---|
| VPC | `10.20.0.0/16` |
| Private subnet | `10.20.1.0/24` |
| Public IPv4 | None |
| Internet Gateway | None |
| NAT Gateway | None |
| SSH key pair | None |
| EC2 inbound rules | None |

The subnet route table contained local VPC routing and the AWS-managed prefix-list route associated with the S3 gateway endpoint.

There was no:

```text
0.0.0.0/0 → Internet Gateway
```

or:

```text
0.0.0.0/0 → NAT Gateway
```

default route.

---

## Administrative Access

Traditional SSH administration was intentionally avoided.

Instead, the EC2 instance was managed using **AWS Systems Manager Session Manager**.

Private interface endpoints provided connectivity to:

```text
com.amazonaws.us-east-2.ssm
com.amazonaws.us-east-2.ssmmessages
```

The endpoint security group allowed HTTPS on TCP port `443` from the EC2 workload security group.

The EC2 security group itself contained **zero inbound rules**.

The Systems Manager agent running on the EC2 instance initiated HTTPS connections to the private endpoints, allowing Session Manager to operate without:

- a public IPv4 address
- inbound TCP port `22`
- an SSH key pair
- an Internet Gateway
- a NAT Gateway

---

## Identity and Access

The EC2 workload used:

```text
BlacksiteEC2Role
```

rather than static AWS access keys.

The role supplied temporary AWS credentials to the instance and included:

```text
AmazonSSMManagedInstanceCore
BlacksiteS3ScopedAccess
```

The custom S3 policy restricted workload access to:

```text
allowed/
```

### Authorized

```text
List allowed/
GetObject allowed/*
PutObject allowed/*
```

### Not Authorized

```text
Read restricted/*
List restricted/
Delete objects
Access unrelated S3 resources
```

The authorization boundary was tested directly rather than assumed from policy configuration alone.

---

## Private S3 Connectivity

The EC2 workload accessed Amazon S3 through an **S3 Gateway VPC Endpoint**.

```mermaid
flowchart LR
    EC2["Private EC2"] -->|"AWS CLI Request"| Endpoint["S3 Gateway Endpoint"]
    Endpoint --> Bucket["Private S3 Bucket"]

    Bucket --> Allowed["allowed/<br/>AUTHORIZED"]
    Bucket --> Restricted["restricted/<br/>DENIED"]
```

This allowed the instance to communicate with S3 without requiring a public internet route.

IAM independently determined whether each requested S3 operation was authorized.

---

## Access-Control Validation

The deployed environment was tested using both positive and negative authorization scenarios.

| Scenario | Expected | Observed |
|---|---:|---:|
| List `allowed/` | Allow | ✅ PASS |
| Download `allowed/mission-brief.txt` | Allow | ✅ PASS |
| Upload object to `allowed/` | Allow | ✅ PASS |
| Download `restricted/admin-only.txt` | Deny | ✅ PASS |
| List `restricted/` | Deny | ✅ PASS |

The restricted object read returned:

```text
403 Forbidden
```

The restricted prefix listing returned:

```text
AccessDenied
```

These results confirmed that the EC2 role could perform the intended operations while access outside its authorized S3 scope was rejected.

---

## Audit Visibility

AWS CloudTrail Event History was used to inspect administrative activity within the environment.

A controlled EC2:

```text
CreateTags
```

operation was generated and traced through CloudTrail.

The event record exposed information including:

```text
userIdentity
eventTime
eventSource
eventName
sourceIPAddress
requestParameters
resources
```

This provided visibility into:

- **Who** initiated an action
- **What** API operation occurred
- **When** it occurred
- **Which resource** was affected

---

## Security Design Summary

| Risk | BLACKSITE Control |
|---|---|
| Public administrative exposure | No public IPv4 and no inbound EC2 rules |
| Exposed SSH service | Systems Manager Session Manager replaces SSH |
| Long-lived AWS credentials | EC2 IAM role provides temporary credentials |
| Excessive S3 permissions | Prefix-scoped IAM policy |
| Unauthorized storage access | Positive and negative authorization testing |
| Public S3 exposure | S3 Block Public Access |
| General internet dependency | Private AWS service endpoints |
| Untracked infrastructure changes | CloudTrail Event History |
| Weak metadata access | IMDSv2 required |

---

## Data and Control Flow

```text
Administrator
      |
      | Starts Session Manager session
      v
AWS Systems Manager
      ^
      |
      | Private SSM / SSMMessages endpoints
      |
EC2 SSM Agent
      |
      | S3 request using temporary IAM credentials
      v
S3 Gateway Endpoint
      |
      v
Private S3 Bucket
      |
      +---- allowed/       AUTHORIZED
      |
      +---- restricted/    DENIED
```

The critical distinction is that the **EC2 instance initiates the Systems Manager connectivity**.

No inbound administrative connection is opened to the workload.

Administrative AWS API activity is independently visible through CloudTrail Event History.

---

## Design Decisions

### Why no public IPv4 address?

The workload did not require direct inbound internet connectivity.

Removing the public address reduced unnecessary public exposure.

### Why no SSH?

Session Manager provided administrative shell access without exposing port `22` or requiring SSH key management.

### Why use an IAM role?

An EC2 IAM role provides temporary AWS credentials automatically and avoids storing long-lived access keys on the host.

### Why use Systems Manager interface endpoints?

The interface endpoints allowed the private EC2 workload to communicate with Systems Manager without requiring general internet connectivity.

### Why use an S3 gateway endpoint?

The gateway endpoint allowed S3 access from the VPC without requiring an Internet Gateway or NAT Gateway.

### Why perform denied-access tests?

A policy that appears correct is not necessarily a policy that behaves correctly.

Negative tests confirmed that the intended authorization boundary was actually enforced by AWS.

---

## Evidence

Supporting validation artifacts are available in the [`evidence/`](../evidence/) directory.

Key evidence includes:

- [No public EC2 address](../evidence/01-private-ec2-no-public-ip.png)
- [No inbound EC2 rules](../evidence/02-no-inbound-rules.png)
- [Private route table](../evidence/03-private-route-table.png)
- [Session Manager access](../evidence/04-session-manager.png)
- [Authorized S3 read](../evidence/05-authorized-read.png)
- [Authorized S3 write](../evidence/06-authorized-write.png)
- [Restricted access denied](../evidence/07-restricted-access-denied.png)
- [Automated validation](../evidence/08-validation-script.png)
- [CloudTrail audit event](../evidence/09-cloudtrail-event.png)

---

## Limitations

BLACKSITE is a controlled security lab rather than a production architecture.

The implementation used:

- One AWS Region
- One Availability Zone
- One EC2 workload
- Manual infrastructure provisioning
- No centralized SIEM
- No automated remediation
- No production or sensitive data

The live AWS infrastructure was intentionally removed after validation.

The repository preserves the architecture, IAM policy, automation, validation results, and supporting evidence.
