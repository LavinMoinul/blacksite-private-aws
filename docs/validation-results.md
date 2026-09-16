<div align="center">

# BLACKSITE Validation Results

### Observed Security and Access-Control Test Results

**12 tests executed • 12 tests passed**

</div>

---

## Summary

BLACKSITE was validated against the network, administration, IAM, storage-access, and auditing requirements defined in the [Validation Plan](test-plan.md).

All planned controls behaved as expected.

| Category | Passed | Failed |
|---|---:|---:|
| Network Isolation | 4 | 0 |
| Administration | 1 | 0 |
| IAM / S3 Authorization | 5 | 0 |
| Auditing | 2 | 0 |
| **Total** | **12** | **0** |

---

## Results Matrix

| ID | Test | Result | Evidence |
|---|---|---:|---|
| NET-01 | EC2 has no public IPv4 address | ✅ PASS | [01-private-ec2-no-public-ip.png](../evidence/01-private-ec2-no-public-ip.png) |
| NET-02 | Private route table has no IGW/NAT default route | ✅ PASS | [03-private-route-table.png](../evidence/03-private-route-table.png) |
| NET-03 | EC2 security group has no inbound rules | ✅ PASS | [02-no-inbound-rules.png](../evidence/02-no-inbound-rules.png) |
| ADM-01 | Session Manager administrative access succeeds | ✅ PASS | [04-session-manager.png](../evidence/04-session-manager.png) |
| NET-04 | Direct public internet request fails | ✅ PASS | Observed during Session Manager validation |
| IAM-01 | List authorized S3 prefix | ✅ PASS | [05-authorized-read.png](../evidence/05-authorized-read.png) |
| IAM-02 | Download authorized S3 object | ✅ PASS | [05-authorized-read.png](../evidence/05-authorized-read.png) |
| IAM-03 | Upload object to authorized S3 prefix | ✅ PASS | [06-authorized-write.png](../evidence/06-authorized-write.png) |
| IAM-04 | Read restricted S3 object is denied | ✅ PASS | [07-restricted-access-denied.png](../evidence/07-restricted-access-denied.png) |
| IAM-05 | List restricted S3 prefix is denied | ✅ PASS | [08-validation-script.png](../evidence/08-validation-script.png) |
| AUD-01 | Generate controlled EC2 management event | ✅ PASS | [09-cloudtrail-event.png](../evidence/09-cloudtrail-event.png) |
| AUD-02 | Locate and inspect event in CloudTrail | ✅ PASS | [09-cloudtrail-event.png](../evidence/09-cloudtrail-event.png) |

---

## Network Isolation

### NET-01 — No Public IPv4 Address

**Result:** ✅ PASS

The EC2 workload was deployed with a private IPv4 address and no public IPv4 assignment.

```text
Public IPv4: None
Private address: 10.20.1.x
```

This confirmed that the instance was not directly addressable from the public internet.

**Evidence:**  
[01-private-ec2-no-public-ip.png](../evidence/01-private-ec2-no-public-ip.png)

---

### NET-02 — No Internet Gateway or NAT Default Route

**Result:** ✅ PASS

The private subnet route table was inspected and contained no conventional internet default route through an Internet Gateway or NAT Gateway.

No route similar to either of the following was present:

```text
0.0.0.0/0 → Internet Gateway
0.0.0.0/0 → NAT Gateway
```

Private S3 connectivity was instead provided through the S3 gateway endpoint.

**Evidence:**  
[03-private-route-table.png](../evidence/03-private-route-table.png)

---

### NET-03 — No Inbound EC2 Rules

**Result:** ✅ PASS

The security group attached to the EC2 workload contained no inbound rules.

```text
Inbound rules: None
```

No SSH, administrative, or application port was exposed to the network.

**Evidence:**  
[02-no-inbound-rules.png](../evidence/02-no-inbound-rules.png)

---

### NET-04 — Direct Internet Connectivity

**Result:** ✅ PASS

A direct HTTPS request to a public internet destination was attempted from the EC2 workload.

```bash
curl -I --connect-timeout 5 --max-time 8 https://example.com
```

The request failed as expected.

At the same time, private AWS service connectivity remained functional through the configured VPC endpoints.

This demonstrated that BLACKSITE could communicate with required AWS services without providing the workload with a general-purpose internet route.

---

## Private Administration

### ADM-01 — Systems Manager Session Manager

**Result:** ✅ PASS

A browser-based shell session was successfully established with the EC2 instance through AWS Systems Manager Session Manager.

The connection succeeded despite the instance having:

```text
No public IPv4 address
No SSH key pair
No inbound security-group rules
```

This validated the private administrative-access design.

**Evidence:**  
[04-session-manager.png](../evidence/04-session-manager.png)

---

## IAM and S3 Authorization

The EC2 workload operated under:

```text
BlacksiteEC2Role
```

with the custom policy:

```text
BlacksiteS3ScopedAccess
```

The policy was intended to permit access to:

```text
allowed/
```

while preventing access to:

```text
restricted/
```

Both sides of the authorization boundary were tested.

---

### IAM-01 — Authorized Prefix Listing

**Result:** ✅ PASS

The workload successfully listed objects within:

```text
allowed/
```

This confirmed that the role possessed the intended `s3:ListBucket` permission for the authorized prefix.

**Evidence:**  
[05-authorized-read.png](../evidence/05-authorized-read.png)

---

### IAM-02 — Authorized Object Download

**Result:** ✅ PASS

The workload successfully downloaded:

```text
allowed/mission-brief.txt
```

using its EC2 IAM role.

No static AWS credentials were required.

**Evidence:**  
[05-authorized-read.png](../evidence/05-authorized-read.png)

---

### IAM-03 — Authorized Object Upload

**Result:** ✅ PASS

The workload successfully uploaded a validation object into:

```text
allowed/
```

This confirmed that the scoped `s3:PutObject` permission functioned as intended.

**Evidence:**  
[06-authorized-write.png](../evidence/06-authorized-write.png)

---

### IAM-04 — Restricted Object Read

**Result:** ✅ PASS

The workload attempted to retrieve:

```text
restricted/admin-only.txt
```

The operation was rejected by AWS.

Observed response:

```text
403 Forbidden
```

The failure was expected and therefore represents a successful security test.

**Evidence:**  
[07-restricted-access-denied.png](../evidence/07-restricted-access-denied.png)

---

### IAM-05 — Restricted Prefix Listing

**Result:** ✅ PASS

The EC2 role attempted to enumerate:

```text
restricted/
```

AWS returned:

```text
AccessDenied
```

The response identified the assumed `BlacksiteEC2Role` session and confirmed that no identity-based policy permitted the requested `s3:ListBucket` operation for that prefix.

The automated validation script also reproduced the expected authorization behavior.

**Evidence:**  
[08-validation-script.png](../evidence/08-validation-script.png)

---

## Automated Validation

The reusable Bash validation script executed the primary S3 authorization tests.

Observed result:

```text
[PASS] Authorized prefix accessible
[PASS] Authorized object download succeeded
[PASS] Authorized object upload succeeded
[PASS] Restricted object access denied
```

This provided a repeatable check of both permitted and prohibited operations.

**Evidence:**  
[08-validation-script.png](../evidence/08-validation-script.png)

**Script:**  
[`scripts/validate-access.sh`](../scripts/validate-access.sh)

---

## CloudTrail Audit Validation

### AUD-01 — Controlled Management Event

**Result:** ✅ PASS

A controlled tag modification was performed against the EC2 instance:

```text
Validation = BLACKSITE
```

The action generated an EC2:

```text
CreateTags
```

API event.

---

### AUD-02 — CloudTrail Event Inspection

**Result:** ✅ PASS

The generated `CreateTags` event was located in AWS CloudTrail Event History.

The event record contained audit information including:

```text
userIdentity
eventTime
eventSource
eventName
sourceIPAddress
requestParameters
resources
```

This demonstrated that the administrative action could be traced back to its identity, API operation, time, and affected resource.

**Evidence:**  
[09-cloudtrail-event.png](../evidence/09-cloudtrail-event.png)

---

## Final Validation Status

```text
NETWORK ISOLATION        PASS
PRIVATE ADMINISTRATION   PASS
IAM AUTHORIZATION        PASS
NEGATIVE ACCESS TESTING  PASS
AUDIT VISIBILITY         PASS
```

### Overall Result: ✅ PASS

BLACKSITE met the security objectives defined for the lab:

- the EC2 workload was not publicly addressed
- no inbound administrative ports were exposed
- administration remained available through Systems Manager
- AWS permissions were delivered through temporary role credentials
- authorized S3 operations succeeded
- unauthorized S3 operations were rejected
- management activity was observable through CloudTrail

The live AWS deployment was subsequently removed according to the [Cleanup Runbook](cleanup.md), while the repository preserves the configuration, validation logic, documentation, and supporting evidence.
