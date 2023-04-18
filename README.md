# Creditorwatch
Requirement : Using terraform to provision a stack on AWS that runs a nginx image and  expose it to Internet.

Solution : 

This Terraform code defines a VPC, two public subnets. Ecs is binded with Application Load Balancer.

For public access. ALB is binded to cloudfront which in turn binded to route53.

This architecture leverages AWS config, AWS Cloudtrial, AWS WAF, well configured ALB and best practice VPC configurations for security, also minimal ecs resource configurations for cost optimization.
