# Lab 2A — CloudFront, WAF, Origin Cloaking, Path-Based Caching

## What was built

- **CloudFront** in front of the existing ALB (apex + app aliases, HTTPS viewer cert).
- **WAF** at CloudFront scope (AWS managed Common + KnownBadInputs).
- **Route 53** A (alias) records for apex and `app.` pointing at CloudFront.
- **Origin cloaking:** (1) ALB security group restricted to CloudFront prefix list; (2) listener rule forwards only when custom header `X-Chewbacca-Growl` matches.
- **Path-based cache:** `/api/public-feed` (origin-driven), `/api/*` (no cache), `/static/*` (aggressive), default (CachingDisabled).

## Prerequisites (foundation lab)

The following must already exist (from a prior foundation lab):

- ALB: `{var.project}-alb01`
- HTTPS listener on port 443 with default action 403
- ALB security group: `{var.project}-alb-sg01`
- Target group: `{var.project}-tg01`
- Route 53 hosted zone for `var.domain_name`
- ACM certificate in **us-east-1** for `var.domain_name`

## Deploy

```bash
cd Lab2/Lab2A
terraform init
terraform plan
terraform apply
# Set origin_secret via TF_VAR_origin_secret or in terraform.tfvars (do not commit secrets)
```

## Deliverables and verification

- **Deliverables layout:** `deliverables/` contains `proof/`, `verification/`, and `docs/`.
- **What each proof means:** See `deliverables/docs/2a_proof_map.txt`.
- **Index:** See `deliverables/docs/2a_deliverables_index.txt`.

### Run the verification script

From the **repo root** (parent of `Lab2/`):

```bash
# Get values from Terraform (run from repo root)
cd /path/to/Armageddon
export DIST_ID=$(terraform -chdir=Lab2/Lab2A output -raw cloudfront_distribution_id)
export ALB_DNS=$(terraform -chdir=Lab2/Lab2A output -raw alb_dns)
export HOSTED_ZONE_ID=$(terraform -chdir=Lab2/Lab2A output -raw hosted_zone_id)
export HOSTNAME="app.cloudyjones.xyz"   # or your apex, e.g. cloudyjones.xyz
export AWS_REGION=us-east-1

./Lab2/Lab2A/scripts/verify_lab2a.sh
```

Outputs are written to `Lab2/Lab2A/deliverables/verification/`. After the run:

1. Copy `deliverables/docs/2a_verification_results_template.txt` into `deliverables/verification/verification_results.txt`, then fill in Date, Current status, and Follow-ups.
2. Regenerate the deliverables tree (optional):  
   `find Lab2/Lab2A/deliverables -print | sort > Lab2/Lab2A/deliverables/docs/2a_deliverables_tree.txt`

### Zip deliverables for submission

```bash
cd Lab2/Lab2A && zip -r lab2a_deliverables.zip deliverables
```

## Important verification outputs

- **cloudfront_behaviors.txt** — Should show `/api/public-feed`, `/api/*`, `/static/*`.
- **waf_for_distribution.txt** — Should show WAF attached to the distribution.
- **alb_direct_headers.txt** — Should show **403** (origin cloaking: direct ALB access blocked).

Direct ALB is tested with `curl -sIk "https://$ALB_DNS"` (HTTPS; `-k` skips cert validation for the ALB hostname).
