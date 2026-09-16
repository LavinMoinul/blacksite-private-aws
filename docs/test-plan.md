<div align="center">

# BLACKSITE Validation Plan

### Security and Access-Control Test Matrix

</div>

---

## Purpose

This validation plan verifies that BLACKSITE behaves as designed across four areas:

- **Network isolation**
- **Private administration**
- **Least-privilege IAM**
- **Audit visibility**

The environment is considered successfully validated only if both positive and negative test cases behave as expected.

---

## Test Matrix

| ID | Category | Test | Expected Result |
|---|---|---|---|
| NET-01 | Networking | Inspect EC2 addressing | No public IPv4 address |
| NET-02 | Networking | Inspect private route table | No Internet Gateway or NAT default route |
| NET-03 | Networking | Inspect EC2 security group | No inbound rules |
| ADM-01 | Administration | Connect through Systems Manager Session Manager | Success |
| NET-04 | Networking | Attempt direct public internet request | Connection fails |
| IAM-01 | IAM / S3 | List `allowed/` prefix | Success |
| IAM-02 | IAM / S3 | Download object from `allowed/` | Success |
| IAM-03 | IAM / S3 | Upload object to `allowed/` | Success |
| IAM-04 | IAM / S3 | Read object from `restricted/` | Denied |
| IAM-05 | IAM / S3 | List `restricted/` prefix | Denied |
| AUD-01 | Auditing | Generate controlled EC2 management event | Success |
| AUD-02 | Auditing | Locate management event in CloudTrail Event History | Success |

---

## Network Isolation Tests

### NET-01 — Public Address Validation

**Objective:** Confirm that the EC2 workload is not directly addressable from the public internet.

**Procedure:**

Inspect the EC2 instance networking details.

**Expected result:**

```text
Public IPv4 address: None
Private IPv4 address: 10.20.1.x
```

**Security property validated:**

The workload is privately addressed.

---

### NET-02 — Route Table Validation

**Objective:** Confirm that the private subnet has no conventional internet route.

**Procedure:**

Inspect:

```text
blacksite-private-rt
```

**Expected result:**

No route similar to:

```text
0.0.0.0/0 → Internet Gateway
```

and no route similar to:

```text
0.0.0.0/0 → NAT Gateway
```

The S3 gateway endpoint route is expected.

**Security property validated:**

The workload cannot reach the public internet through an IGW or NAT path.

---

### NET-03 — Inbound Firewall Validation

**Objective:** Confirm that the EC2 workload does not expose administrative or application ports.

**Procedure:**

Inspect:

```text
blacksite-instance-sg
```

**Expected result:**

```text
Inbound rules: None
```

**Security property validated:**

No direct inbound network access is permitted to the workload.

---

### NET-04 — Public Internet Connectivity Test

**Objective:** Verify the absence of normal outbound internet connectivity.

**Procedure:**

From the EC2 instance:

```bash
curl -I --connect-timeout 5 --max-time 8 https://example.com
```

**Expected result:**

The request times out or fails to connect.

**Security property validated:**

The workload does not rely on a public internet route.

---

## Administrative Access Test

### ADM-01 — Session Manager Access

**Objective:** Verify that the private EC2 instance remains administratively accessible without SSH.

**Procedure:**

Connect through:

```text
EC2
→ Connect
→ Session Manager
```

**Expected result:**

A browser-based shell opens successfully.

**Security property validated:**

Administrative access is available without a public IPv4 address, SSH key pair, or inbound port `22`.

---

## IAM and S3 Authorization Tests

The EC2 instance role is intentionally permitted to access:

```text
allowed/
```

while access to:

```text
restricted/
```

is denied.

### IAM-01 — Authorized Prefix Listing

**Procedure:**

```bash
aws s3 ls "s3://$BUCKET/allowed/" --region "$REGION"
```

**Expected result:**

The authorized objects are listed successfully.

---

### IAM-02 — Authorized Object Read

**Procedure:**

```bash
aws s3 cp \
  "s3://$BUCKET/allowed/mission-brief.txt" \
  /tmp/mission-brief.txt \
  --region "$REGION"
```

**Expected result:**

The object downloads successfully.

---

### IAM-03 — Authorized Object Write

**Procedure:**

Upload a test object to:

```text
allowed/
```

**Expected result:**

The upload succeeds.

---

### IAM-04 — Restricted Object Read

**Procedure:**

Attempt to download:

```text
restricted/admin-only.txt
```

**Expected result:**

The request is rejected with:

```text
403 Forbidden
```

or:

```text
AccessDenied
```

**Security property validated:**

The workload cannot read objects outside its authorized S3 scope.

---

### IAM-05 — Restricted Prefix Listing

**Procedure:**

```bash
aws s3 ls "s3://$BUCKET/restricted/" --region "$REGION"
```

**Expected result:**

The request returns:

```text
AccessDenied
```

**Security property validated:**

The workload cannot enumerate the restricted prefix.

---

## Audit Validation Tests

### AUD-01 — Generate a Controlled Management Event

**Objective:** Create a predictable AWS management action that can be audited.

**Procedure:**

Add the following tag to the EC2 instance:

```text
Validation = BLACKSITE
```

**Expected result:**

AWS accepts the tag change and generates an EC2 `CreateTags` API event.

---

### AUD-02 — Locate the Event in CloudTrail

**Objective:** Verify that AWS management activity is visible for investigation.

**Procedure:**

Open:

```text
CloudTrail
→ Event history
```

Filter by:

```text
Event name = CreateTags
```

Inspect the event record.

**Expected result:**

The event contains information including:

```text
userIdentity
eventTime
eventSource
eventName
sourceIPAddress
requestParameters
resources
```

**Security property validated:**

Administrative infrastructure changes can be reconstructed from AWS audit data.

---

## Validation Criteria

BLACKSITE passes validation when all of the following are true:

```text
✓ No public EC2 address
✓ No inbound EC2 rules
✓ No Internet Gateway or NAT default route
✓ Session Manager administration succeeds
✓ Normal public internet request fails
✓ Authorized S3 operations succeed
✓ Restricted S3 operations fail
✓ CloudTrail records the controlled management event
```

The corresponding observed results are documented in:

[Validation Results](validation-results.md)
