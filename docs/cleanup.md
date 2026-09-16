<div align="center">

# BLACKSITE Cleanup Runbook

### Safe Teardown of the AWS Lab Environment

</div>

---

## Purpose

BLACKSITE was built as a temporary AWS security lab.

After validation was complete, the live AWS infrastructure was intentionally removed to:

- prevent unnecessary AWS credit usage
- avoid leaving unused cloud resources running
- reduce exposure from forgotten infrastructure
- demonstrate clean lifecycle management
- preserve the project through documentation and evidence rather than idle resources

The GitHub repository remains the permanent record of the project.

---

## Cleanup Order

Resources were removed in dependency-safe order.

### 1. Terminate the EC2 Instance

Terminate:

```text
blacksite-private-ec2
```

This removes the live compute workload before deleting the surrounding network infrastructure.

---

### 2. Delete Systems Manager Interface Endpoints

Delete:

```text
blacksite-ssm-endpoint
blacksite-ssmmessages-endpoint
```

If the compatibility endpoint was created, also delete:

```text
blacksite-ec2messages-endpoint
```

These interface endpoints should be removed promptly because they consume AWS resources while provisioned.

---

### 3. Delete the S3 Gateway Endpoint

Delete:

```text
blacksite-s3-endpoint
```

This removes the private S3 network path from the VPC route table.

---

### 4. Remove the S3 Bucket

Before deleting the bucket:

1. Empty all objects.
2. Confirm no required evidence depends on the live bucket.
3. Delete the bucket.

The GitHub repository preserves the IAM policy, validation results, screenshots, and documentation after the bucket is removed.

---

### 5. Remove IAM Resources

Open:

```text
BlacksiteEC2Role
```

Delete the inline policy:

```text
BlacksiteS3ScopedAccess
```

Then delete:

```text
BlacksiteEC2Role
```

This removes the temporary workload permissions created for the lab.

---

### 6. Delete Security Groups

Delete:

```text
blacksite-instance-sg
blacksite-endpoint-sg
```

If AWS reports that a security group is still in use, wait for the associated endpoint network interfaces to finish deleting and retry.

---

### 7. Delete the Private Subnet

Delete:

```text
blacksite-private-subnet
```

---

### 8. Delete the Custom Route Table

Delete:

```text
blacksite-private-rt
```

---

### 9. Delete the VPC

Finally, delete:

```text
blacksite-vpc
```

At this point the live BLACKSITE deployment has been fully removed.

---

## Cleanup Checklist

| Resource | Expected Final State |
|---|---|
| EC2 instance | Terminated |
| SSM endpoint | Deleted |
| SSM Messages endpoint | Deleted |
| EC2 Messages endpoint | Deleted if created |
| S3 gateway endpoint | Deleted |
| S3 bucket | Deleted |
| Custom IAM policy | Deleted |
| EC2 IAM role | Deleted |
| Instance security group | Deleted |
| Endpoint security group | Deleted |
| Private subnet | Deleted |
| Custom route table | Deleted |
| VPC | Deleted |

---

## What Remains After Teardown

The live infrastructure is intentionally disposable.

The permanent project artifacts remain in the repository:

```text
README.md
docs/
evidence/
policies/
scripts/
```

These preserve:

- the architecture
- threat model
- IAM policy
- validation script
- test plan
- validation results
- CloudTrail evidence
- access-control evidence
- cleanup procedure

---

## CloudTrail Event History

CloudTrail Event History does not require manual cleanup.

It is an AWS account-level service used during the project to review recent management activity.

No dedicated CloudTrail trail was created for BLACKSITE.

---

## Final State

After cleanup, BLACKSITE no longer has active AWS infrastructure.

The project remains reproducible through its documentation, security policy, validation logic, and recorded evidence.

This separation between **persistent project artifacts** and **temporary cloud infrastructure** was intentional.
