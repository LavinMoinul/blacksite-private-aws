\# BLACKSITE Validation Plan



| ID | Test | Expected Result |

|---|---|---|

| NET-01 | Inspect EC2 addressing | No public IPv4 address |

| NET-02 | Inspect private route table | No IGW/NAT default route |

| NET-03 | Inspect EC2 security group | No inbound rules |

| ADM-01 | Connect through Session Manager | Success |

| NET-04 | Attempt public internet request | Failure |

| IAM-01 | List allowed S3 prefix | Success |

| IAM-02 | Download allowed object | Success |

| IAM-03 | Upload allowed object | Success |

| IAM-04 | Read restricted object | AccessDenied |

| IAM-05 | List restricted prefix | AccessDenied |

| AUD-01 | Generate EC2 management event | Success |

| AUD-02 | Locate event in CloudTrail | Success |

