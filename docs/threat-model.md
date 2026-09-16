<div align="center">

# BLACKSITE Threat Model

### Security Risks, Controls, and Validation

</div>

---

## Scope

BLACKSITE is a controlled AWS security lab built around a privately deployed EC2 workload.

The threat model focuses on risks introduced by:

- public administrative exposure
- long-lived credentials
- excessive IAM permissions
- unintended S3 exposure
- untracked infrastructure changes
- unnecessary internet connectivity

The environment contains no production data and is not intended to represent a full enterprise threat model.

---

## Threat Summary

| Threat | Primary Control | Validation |
|---|---|---|
| Public administrative exposure | No public IPv4, no inbound EC2 rules, Session Manager | Network and Session Manager tests |
| Long-lived AWS credentials | EC2 IAM instance role | Instance-role verification |
| Excessive S3 access | Prefix-scoped IAM policy | Authorized and denied S3 tests |
| Public object exposure | S3 Block Public Access | Bucket configuration |
| Unnecessary internet connectivity | No IGW or NAT route | Direct internet request fails |
| Untracked administrative activity | CloudTrail Event History | Controlled `CreateTags` audit test |

---

## 1. Public Administrative Exposure

### Risk

A publicly reachable administrative service increases the attack surface of a cloud workload.

Common examples include:

```text
Public IPv4 address
SSH exposed on TCP/22
Internet-routable management interface
Long-lived SSH keys
```

An internet-facing administrative endpoint may be targeted by credential attacks, scanning, exploitation attempts, or configuration mistakes.

### BLACKSITE Control

The EC2 workload was deployed with:

```text
No public IPv4 address
No Internet Gateway
No NAT Gateway
No SSH key pair
No inbound security-group rules
```

Administration was performed through:

```text
AWS Systems Manager Session Manager
```

using private VPC interface endpoints.

### Validation

The deployment was verified by:

- inspecting the EC2 instance for the absence of a public IPv4 address
- confirming the EC2 security group contained zero inbound rules
- confirming the subnet route table contained no IGW or NAT default route
- successfully opening a Session Manager shell

### Residual Risk

Administrative access still depends on AWS identity and authorization controls.

Compromise of an authorized AWS identity could still permit access through Systems Manager.

---

## 2. Long-Lived AWS Credentials

### Risk

Static AWS access keys stored on a workload can be:

- accidentally committed to source control
- exposed through files or environment variables
- stolen after host compromise
- forgotten and left active indefinitely

### BLACKSITE Control

The EC2 instance used:

```text
BlacksiteEC2Role
```

as its IAM instance role.

AWS supplied temporary role credentials to the instance rather than requiring manually stored access keys.

### Validation

The instance metadata service was queried to verify that the workload was operating under:

```text
BlacksiteEC2Role
```

No permanent AWS access keys were configured on the EC2 host.

### Residual Risk

Temporary credentials can still be abused while valid if the instance itself is compromised.

For that reason, minimizing the permissions granted to the role remains necessary.

---

## 3. Excessive S3 Permissions

### Risk

A workload with overly broad storage permissions could expose or modify data beyond its intended scope.

Examples of risky permissions include:

```json
"Action": "s3:*"
```

or:

```json
"Resource": "*"
```

### BLACKSITE Control

The custom IAM policy:

```text
BlacksiteS3ScopedAccess
```

restricted the workload to the:

```text
allowed/
```

prefix of the BLACKSITE S3 bucket.

Authorized actions were limited to the operations required by the lab.

The workload was not granted access to:

```text
restricted/
```

### Validation

Positive tests confirmed that the workload could:

```text
List allowed/
Read allowed/*
Write allowed/*
```

Negative tests confirmed that it could not:

```text
Read restricted/*
List restricted/
```

The denied requests returned:

```text
403 Forbidden
```

and:

```text
AccessDenied
```

### Residual Risk

The role still possesses write access to its authorized prefix.

A compromised workload could therefore modify objects within `allowed/`.

A production design could further separate read-only and write permissions when appropriate.

---

## 4. Public Object Storage

### Risk

Misconfigured object storage can unintentionally expose data to unauthenticated users.

### BLACKSITE Control

The S3 bucket retained:

```text
S3 Block Public Access
```

and was accessed by the EC2 workload through IAM authorization.

No public bucket access was required for the project.

### Validation

The workload accessed S3 through authenticated AWS CLI requests using its IAM role.

The architecture did not depend on anonymous or public object access.

### Residual Risk

Future bucket-policy changes could weaken the storage boundary.

A production environment should continuously monitor S3 configuration changes.

---

## 5. Unnecessary Internet Connectivity

### Risk

General-purpose outbound internet access can provide an additional path for:

- malicious downloads
- command-and-control traffic
- data exfiltration
- unintended external dependencies

### BLACKSITE Control

The private subnet contained no:

```text
Internet Gateway route
NAT Gateway route
```

AWS service connectivity required by the workload was provided through private endpoints instead.

S3 traffic used:

```text
S3 Gateway VPC Endpoint
```

Systems Manager traffic used private interface endpoints.

### Validation

A direct request to:

```text
https://example.com
```

from the EC2 workload failed as expected.

Private AWS service access continued to function.

### Residual Risk

Private access to authorized AWS services still exists.

Network isolation therefore complements, rather than replaces, IAM authorization.

---

## 6. Untracked Administrative Activity

### Risk

Changes to cloud infrastructure without audit visibility can make it difficult to determine:

- who performed an action
- what changed
- when it occurred
- which resource was affected

### BLACKSITE Control

AWS CloudTrail Event History was used to inspect management activity.

### Validation

A controlled EC2 tag change generated a:

```text
CreateTags
```

management event.

The CloudTrail record exposed fields including:

```text
userIdentity
eventTime
eventSource
eventName
sourceIPAddress
requestParameters
resources
```

This allowed the administrative action to be reconstructed after it occurred.

### Residual Risk

BLACKSITE used Event History rather than a dedicated centralized logging architecture.

A production environment would typically retain logs for longer periods and forward them to centralized monitoring or SIEM infrastructure.

---

## Security Boundaries

BLACKSITE relies on several independent security boundaries rather than a single control.

```text
Network Isolation
        |
        v
No Public Administrative Exposure
        |
        v
Private Systems Manager Access
        |
        v
Temporary IAM Credentials
        |
        v
Least-Privilege S3 Permissions
        |
        v
Positive + Negative Validation
        |
        v
CloudTrail Audit Visibility
```

A failure in one layer does not automatically eliminate every other control.

---

## Assumptions

The threat model assumes:

- AWS-managed services operate as documented
- the AWS account owner remains trusted
- the EC2 operating system is not already compromised
- test files contain no real sensitive information
- IAM and networking configurations match the documented deployment
- the lab remains a single-account, single-workload environment

---

## Out of Scope

The following were intentionally outside the scope of BLACKSITE:

```text
Application-layer vulnerabilities
Malware detection
Endpoint detection and response
Multi-account AWS architecture
SIEM integration
Automated remediation
DDoS protection
Container security
Production data classification
High availability
Multi-Region resilience
```

These areas could be addressed in future iterations or separate security projects.

---

## Conclusion

BLACKSITE reduces exposure primarily by removing unnecessary public connectivity and enforcing narrow AWS permissions.

The design combines:

```text
Private networking
Systems Manager administration
Temporary IAM credentials
Prefix-scoped S3 permissions
Negative authorization testing
CloudTrail audit visibility
```

The controls were validated through observed behavior rather than documented configuration alone.
