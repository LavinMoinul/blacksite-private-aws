\# BLACKSITE Threat Model



\## Public Administrative Exposure



\### Risk



A publicly reachable server with an exposed administrative service

increases the internet-facing attack surface.



\### Control



The BLACKSITE EC2 instance has no public IPv4 address, no inbound

security-group rules, and no Internet Gateway or NAT Gateway route.

Administration is performed through AWS Systems Manager Session

Manager.



\## Long-Lived AWS Credentials



\### Risk



Static AWS credentials stored on a host could be exposed or stolen.



\### Control



The workload uses an EC2 IAM instance role that supplies temporary AWS

credentials.



\## Excessive Storage Permissions



\### Risk



A compromised workload could access data beyond what it requires.



\### Control



The EC2 role is restricted to the `allowed/` prefix of the BLACKSITE

S3 bucket.



Negative authorization testing verifies that access to `restricted/`

is denied.



\## Public Object Storage



\### Risk



Stored objects could accidentally become publicly accessible.



\### Control



S3 Block Public Access remains enabled on the BLACKSITE bucket.



\## Untracked Administrative Activity



\### Risk



Infrastructure configuration changes could occur without visibility.



\### Control



AWS CloudTrail Event History provides a searchable record of recent

AWS management actions.

