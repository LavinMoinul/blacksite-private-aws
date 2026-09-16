\# BLACKSITE - Private AWS Security Environment



BLACKSITE is a private AWS infrastructure-security lab designed around

minimizing unnecessary public exposure and validating least-privilege

access.



The environment contains an Amazon Linux EC2 workload deployed without

a public IPv4 address, Internet Gateway, NAT Gateway, inbound

administrative ports, or SSH key pair.



The instance is administered through AWS Systems Manager Session

Manager using private VPC interface endpoints and accesses Amazon S3

through an S3 gateway endpoint.



AWS permissions are delivered through an EC2 IAM instance role rather

than long-lived access keys. The workload is authorized to access only

a designated S3 prefix, and negative authorization tests verify that

access outside that scope is denied.



AWS CloudTrail Event History is used to audit administrative activity.



\## Security Goals



\- Eliminate direct public administrative exposure

\- Use temporary IAM role credentials instead of stored AWS keys

\- Apply least-privilege storage permissions

\- Validate authorization through positive and negative tests

\- Maintain visibility into administrative AWS activity

\- Document architecture, testing, limitations, and cleanup



\## Architecture



See \[Architecture](docs/architecture.md).



\## Threat Model



See \[Threat Model](docs/threat-model.md).



\## Validation



\- \[Test Plan](docs/test-plan.md)

\- \[Validation Results](docs/validation-results.md)



\## Repository Structure



```text

.

├── README.md

├── docs/

├── evidence/

├── policies/

└── scripts/

