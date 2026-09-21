\# SecureScale AWS



SecureScale is a secure, highly available AWS application infrastructure platform built to demonstrate production-style cloud engineering, Infrastructure as Code, configuration management, CI validation, monitoring, and automation.



The environment uses a multi-tier VPC architecture with an internet-facing Application Load Balancer distributing traffic to EC2 application servers running in private subnets. An Auto Scaling Group maintains application availability and automatically replaces failed instances, while the database tier remains isolated in private database subnets.



The infrastructure is provisioned with Terraform, configured with Ansible through AWS Systems Manager, monitored with Amazon CloudWatch, validated through GitHub Actions, and supported by Python/Boto3 automation.



\## Project Goals



\- Build secure AWS infrastructure using Infrastructure as Code.

\- Keep application servers and the database out of direct public access.

\- Provide high availability across multiple Availability Zones.

\- Automatically scale and replace failed application instances.

\- Manage private EC2 instances without opening SSH.

\- Automate server configuration with Ansible.

\- Store Terraform state remotely with locking and versioning.

\- Validate Terraform changes automatically with GitHub Actions.

\- Monitor infrastructure health with CloudWatch.

\- Use Python and Boto3 to query AWS infrastructure programmatically.



\## Architecture



Internet Users

&#x20;     |

&#x20;     v

Application Load Balancer

(Public Subnets - Multi-AZ)

&#x20;     |

&#x20;     v

EC2 Auto Scaling Group

(Private App Subnets - Multi-AZ)

&#x20;     |

&#x20;     v

Amazon RDS

(Private Database Subnets)



Supporting Services:

\- Internet Gateway provides public connectivity to the ALB.

\- NAT Gateway provides outbound internet access for private application servers.

\- Security Groups restrict traffic between infrastructure tiers.

\- AWS Systems Manager provides secure EC2 management without SSH or public IP addresses.

\- AWS Secrets Manager protects database credentials.

\- CloudWatch monitors infrastructure health.

\- Terraform provisions the AWS infrastructure.

\- Ansible configures the EC2 application servers.

\- GitHub Actions performs automated Terraform CI checks.

\- Python/Boto3 provides programmatic infrastructure health reporting.

\- Amazon S3 stores the shared Terraform state with versioning, encryption, and state locking.



\## Technologies Used



\*\*AWS\*\*

\- VPC

\- EC2

\- Application Load Balancer

\- Auto Scaling

\- RDS

\- S3

\- IAM

\- Systems Manager

\- Secrets Manager

\- CloudWatch



\*\*Infrastructure \& Automation\*\*

\- Terraform

\- Ansible

\- Python / Boto3

\- GitHub Actions

\- Git / GitHub



\## Security Design



SecureScale follows a layered security model:



\- The Application Load Balancer is the public entry point to the application.

\- EC2 application servers run in private subnets without public IP addresses.

\- Application security groups only allow application traffic from the ALB security group.

\- The RDS database runs in private database subnets.

\- Database traffic is restricted to the application tier.

\- EC2 administration is performed through AWS Systems Manager instead of exposing SSH port 22.

\- IAM roles provide AWS permissions to EC2 instances.

\- Database credentials are managed through AWS Secrets Manager.

\- Terraform state is stored in a private S3 bucket with encryption, versioning, public-access blocking, and state locking.



\## High Availability and Self-Healing



The application tier runs across multiple Availability Zones behind an Application Load Balancer.



The Auto Scaling Group maintains a minimum and desired capacity of two application instances and can scale up to four instances based on CPU utilization.



A failure test was performed by manually terminating one running application instance. The Auto Scaling Group detected the loss and automatically launched a replacement instance. The replacement successfully registered with the load balancer target group and passed its health checks.



\*\*Failure test result: 2 healthy targets, 0 unhealthy targets.\*\*



\## Configuration Management



Ansible dynamically discovers the EC2 application instances using the AWS EC2 dynamic inventory plugin.



Because the application servers are private, Ansible connects through AWS Systems Manager rather than SSH. This allows configuration management without public IP addresses, SSH keys, or inbound port 22.



The Ansible playbook installs and configures Nginx and deploys the application page. Re-running the playbook produced zero additional changes, demonstrating idempotent configuration management.



\## CI Validation



GitHub Actions automatically runs Terraform checks when infrastructure code is pushed to the repository or submitted through a pull request.



The CI workflow performs:



1\. Terraform formatting validation

2\. Terraform initialization

3\. Terraform configuration validation



This provides automated feedback before infrastructure changes progress further.



\## Python / Boto3 Automation



A Python health-reporting script uses Boto3 to communicate directly with AWS APIs.



The script dynamically discovers running SecureScale EC2 instances and reports information including:



\- Instance ID

\- Instance state

\- Private IP address

\- Total number of running application instances



This provides a lightweight programmatic method for checking the application compute tier without manually navigating the AWS console.



\## Terraform State Management



Terraform state is stored remotely in Amazon S3 rather than only on a local workstation.



The state backend includes:



\- S3 remote storage

\- Server-side encryption

\- Bucket versioning

\- Public-access blocking

\- Native Terraform state locking



This creates a safer foundation for collaborative infrastructure management and helps prevent simultaneous Terraform operations from modifying the same state.



\## Key Engineering Decisions



\- Used private application and database tiers to reduce direct internet exposure.

\- Used security-group references to control traffic between infrastructure tiers.

\- Used SSM instead of SSH for private-instance administration.

\- Used AWS-managed database credentials instead of hard-coding passwords.

\- Used a single NAT Gateway for this portfolio environment to reduce cost. A production architecture could use one NAT Gateway per Availability Zone for stronger availability.

\- Used Terraform to make the infrastructure reproducible.

\- Used Ansible for configuration management rather than mixing all server configuration into Terraform.

\- Used GitHub Actions for automated CI validation while keeping infrastructure deployment manually controlled.



\## Repository Structure



```text

securescale-aws/

├── .github/

│   └── workflows/

│       └── terraform-ci.yml

├── ansible/

│   ├── ansible.cfg

│   ├── configure-app.yml

│   └── inventory.aws\_ec2.yml

├── bootstrap/

│   └── main.tf

├── scripts/

│   └── health\_report.py

├── terraform/

│   ├── main.tf

│   ├── outputs.tf

│   ├── variables.tf

│   └── user-data.sh

└── README.md

