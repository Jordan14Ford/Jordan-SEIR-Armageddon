# Lab 3 Working Assumptions

## Account + Environment
- Building in personal AWS account: 583001104385
- Not the class account (200819971986) — ignore that account ID in course materials
- AWS CLI profile: default (or named profile set in terraform.tfvars)
- macOS zsh terminal, files at ~/Desktop/TWC/Armageddon/Lab3/

## Architecture
- PHI at rest only in Tokyo (ap-northeast-1) — APPI requirement
- Sao Paulo (sa-east-1) is stateless compute only — no RDS, no local DB, no backups
- Cross-region DB access goes over TGW — not the public internet
- TGW peering required — VPC peering does not work cross-region
- CloudFront is the public edge — does not cache PHI responses (TTL 0 on API routes)

## Terraform Structure
- Two separate state roots: lab3/tokyo/ and lab3/sao-paulo/
- Tokyo must be applied before Sao Paulo — Sao Paulo reads Tokyo outputs via remote_state
- TGW peering is a two-pass apply:
    Pass 1: Tokyo creates peering attachment (pending-acceptance)
    Pass 2: Sao Paulo accepts it (available)
- terraform.tfvars is gitignored — never commit credentials or passwords

## Naming + Domain
- Domain: chewbacca-growls.com (note the s — not chewbacca-growl.com)
- Project prefix used in all resource names: lab3
- No accented or special characters in AWS resource descriptions (ASCII only)

## Cost Controls
- NAT Gateways: destroy after pip installs, do not leave running between sessions
- RDS: minimize runtime, destroy when not actively needed
- TGW peering: charged per GB transferred, keep test payloads small
- EC2: stop instances between sessions in both regions

## Lab 3B Scripts
- malgus_cloudfront_log_explainer.py may hardcode bucket "Class_Lab3" and prefix "Chwebacca-logs/"
- Verify exact bucket name and prefix in the script before setting up CloudFront logging
- The prefix typo in course materials ("Chwebacca" vs "Chewbacca") needs to be confirmed against the actual script
