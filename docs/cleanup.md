\# BLACKSITE Cleanup Runbook



BLACKSITE contains temporary AWS resources that should be removed after

validation to preserve AWS Free Plan credits.



\## Cleanup Order



1\. Terminate `blacksite-private-ec2`.

2\. Delete `blacksite-ssm-endpoint`.

3\. Delete `blacksite-ssmmessages-endpoint`.

4\. Delete `blacksite-ec2messages-endpoint` if it was created.

5\. Delete `blacksite-s3-endpoint`.

6\. Empty and delete the BLACKSITE S3 bucket.

7\. Delete the inline `BlacksiteS3ScopedAccess` policy.

8\. Delete `BlacksiteEC2Role`.

9\. Delete `blacksite-instance-sg`.

10\. Delete `blacksite-endpoint-sg`.

11\. Delete `blacksite-private-subnet`.

12\. Delete `blacksite-private-rt`.

13\. Delete `blacksite-vpc`.



CloudTrail Event History requires no cleanup because it is provided

automatically by AWS.

