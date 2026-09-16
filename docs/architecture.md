\# BLACKSITE Architecture



BLACKSITE is a private AWS security lab designed around minimizing

public administrative exposure and enforcing least-privilege access.



```mermaid

flowchart TD

&#x20;   Admin\["Administrator"]

&#x20;   SSM\["AWS Systems Manager<br/>Private Interface Endpoints"]

&#x20;   EC2\["Amazon Linux EC2<br/>10.20.1.21<br/>No Public IP<br/>No Inbound Rules"]

&#x20;   S3EP\["S3 Gateway Endpoint"]

&#x20;   S3\["Private S3 Bucket<br/>allowed/ + restricted/"]

&#x20;   CT\["CloudTrail Event History"]



&#x20;   Admin -->|Session Manager| SSM

&#x20;   SSM -->|HTTPS 443| EC2



&#x20;   EC2 -->|Private S3 traffic| S3EP

&#x20;   S3EP --> S3



&#x20;   Admin -->|AWS Management Activity| CT

```



\## Network Design



The EC2 workload is deployed in a private subnet without an Internet

Gateway, NAT Gateway, public IPv4 address, SSH key pair, or inbound

administrative security-group rules.



Administrative access is provided through AWS Systems Manager Session

Manager using private interface VPC endpoints.



Amazon S3 connectivity is provided through an S3 gateway VPC endpoint.



\## Identity and Access



The workload receives temporary AWS credentials through an EC2 IAM

instance role.



The role is restricted to the `allowed/` prefix of the BLACKSITE S3

bucket.



Access to `restricted/` is intentionally denied and validated through

negative authorization testing.



\## Auditing



AWS CloudTrail Event History is used to inspect AWS management activity

and reconstruct administrative actions by identity, API operation,

resource, and timestamp.

