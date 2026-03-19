#!/usr/bin/env bash
# =============================================================================
# AWS EMERGENCY CLEANUP INVENTORY SCRIPT
# Regions: us-east-1 | us-east-2 | ap-northeast-1 | ap-northeast-3 | sa-east-1
# Mode: READ-ONLY — no resources are modified or deleted
# =============================================================================

REGIONS="us-east-1 us-east-2 ap-northeast-1 ap-northeast-3 sa-east-1"

# Color output
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; echo -e "${BOLD}${CYAN}  $1${RESET}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }
subsection() { echo -e "\n${YELLOW}▶ $1${RESET}"; }
warn() { echo -e "${RED}⚠  $1${RESET}"; }


# =============================================================================
# INVENTORY COMMANDS
# =============================================================================
section "INVENTORY COMMANDS"


# ── TRANSIT GATEWAYS (global resource, check per region owner) ────────────────
subsection "TRANSIT GATEWAYS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} Transit Gateways"
  aws ec2 describe-transit-gateways \
    --region $REGION \
    --query "TransitGateways[*].[TransitGatewayId,State,OwnerId,Tags[?Key=='Name'].Value|[0],CreationTime]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── TRANSIT GATEWAY ATTACHMENTS ───────────────────────────────────────────────
subsection "TRANSIT GATEWAY ATTACHMENTS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} TGW Attachments"
  aws ec2 describe-transit-gateway-attachments \
    --region $REGION \
    --query "TransitGatewayAttachments[*].[TransitGatewayAttachmentId,ResourceType,ResourceId,State,Tags[?Key=='Name'].Value|[0]]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── VPC ENDPOINTS ─────────────────────────────────────────────────────────────
subsection "VPC ENDPOINTS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} VPC Endpoints"
  aws ec2 describe-vpc-endpoints \
    --region $REGION \
    --query "VpcEndpoints[*].[VpcEndpointId,VpcEndpointType,ServiceName,State,VpcId]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── NAT GATEWAYS ──────────────────────────────────────────────────────────────
subsection "NAT GATEWAYS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} NAT Gateways (available)"
  aws ec2 describe-nat-gateways \
    --region $REGION \
    --filter "Name=state,Values=available" \
    --query "NatGateways[*].[NatGatewayId,State,VpcId,SubnetId,Tags[?Key=='Name'].Value|[0]]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── ELASTIC IPs ───────────────────────────────────────────────────────────────
subsection "ELASTIC IPs"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} Elastic IPs"
  aws ec2 describe-addresses \
    --region $REGION \
    --query "Addresses[*].[AllocationId,PublicIp,AssociationId,InstanceId,Tags[?Key=='Name'].Value|[0]]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
  # Flag unassociated EIPs (cost $0.005/hr each)
  UNASSOC=$(aws ec2 describe-addresses --region $REGION \
    --query "length(Addresses[?AssociationId==null])" --output text 2>/dev/null)
  [ "$UNASSOC" != "0" ] && [ -n "$UNASSOC" ] && warn "  $UNASSOC unassociated EIP(s) in $REGION — these incur charges!"
done


# ── EC2 INSTANCES ─────────────────────────────────────────────────────────────
subsection "EC2 INSTANCES"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} EC2 Instances (all non-terminated)"
  aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=instance-state-name,Values=running,stopped,stopping,pending" \
    --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],InstanceType,State.Name,LaunchTime,Placement.AvailabilityZone]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── EBS VOLUMES ───────────────────────────────────────────────────────────────
subsection "EBS VOLUMES"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} EBS Volumes"
  aws ec2 describe-volumes \
    --region $REGION \
    --query "Volumes[*].[VolumeId,State,Size,VolumeType,Attachments[0].InstanceId,Tags[?Key=='Name'].Value|[0]]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
  # Flag unattached volumes (still billed)
  UNATTACHED=$(aws ec2 describe-volumes --region $REGION \
    --filters "Name=status,Values=available" \
    --query "length(Volumes)" --output text 2>/dev/null)
  [ "$UNATTACHED" != "0" ] && [ -n "$UNATTACHED" ] && warn "  $UNATTACHED unattached volume(s) in $REGION — still incur charges!"
done


# ── LOAD BALANCERS (ALB / NLB / CLB) ─────────────────────────────────────────
subsection "LOAD BALANCERS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} Load Balancers (ALB/NLB)"
  aws elbv2 describe-load-balancers \
    --region $REGION \
    --query "LoadBalancers[*].[LoadBalancerName,Type,State.Code,DNSName,CreatedTime]" \
    --output table 2>/dev/null || echo "  (none or access denied)"

  echo -e "  Classic Load Balancers:"
  aws elb describe-load-balancers \
    --region $REGION \
    --query "LoadBalancerDescriptions[*].[LoadBalancerName,DNSName,CreatedTime]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── TARGET GROUPS ─────────────────────────────────────────────────────────────
subsection "TARGET GROUPS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} Target Groups"
  aws elbv2 describe-target-groups \
    --region $REGION \
    --query "TargetGroups[*].[TargetGroupName,Protocol,Port,TargetType,LoadBalancerArns[0]]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── RDS DB INSTANCES ──────────────────────────────────────────────────────────
subsection "RDS DB INSTANCES"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} RDS Instances"
  aws rds describe-db-instances \
    --region $REGION \
    --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass,Engine,EngineVersion,MultiAZ]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── RDS SNAPSHOTS ─────────────────────────────────────────────────────────────
subsection "RDS SNAPSHOTS"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} RDS Manual Snapshots (manual only — automated snapshots delete with instance)"
  aws rds describe-db-snapshots \
    --region $REGION \
    --snapshot-type manual \
    --query "DBSnapshots[*].[DBSnapshotIdentifier,DBInstanceIdentifier,Status,SnapshotCreateTime,AllocatedStorage]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# ── WAF WEB ACLs ──────────────────────────────────────────────────────────────
subsection "WAF WEB ACLs"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} WAFv2 Web ACLs (REGIONAL)"
  aws wafv2 list-web-acls \
    --region $REGION \
    --scope REGIONAL \
    --query "WebACLs[*].[Name,Id,ARN]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done
# CloudFront WAF (global, us-east-1 only)
echo -e "\n${GREEN}[global / us-east-1]${RESET} WAFv2 Web ACLs (CLOUDFRONT)"
aws wafv2 list-web-acls \
  --region us-east-1 \
  --scope CLOUDFRONT \
  --query "WebACLs[*].[Name,Id,ARN]" \
  --output table 2>/dev/null || echo "  (none or access denied)"


# ── ROUTE 53 HOSTED ZONES & RECORDS ──────────────────────────────────────────
subsection "ROUTE 53 HOSTED ZONES"
echo -e "\n${GREEN}[global]${RESET} Route 53 Hosted Zones"
aws route53 list-hosted-zones \
  --query "HostedZones[*].[Id,Name,Config.PrivateZone,ResourceRecordSetCount]" \
  --output table 2>/dev/null || echo "  (none or access denied)"

echo -e "\n${GREEN}[global]${RESET} Route 53 Record Sets (first 20 per zone)"
ZONE_IDS=$(aws route53 list-hosted-zones \
  --query "HostedZones[*].Id" --output text 2>/dev/null)
for ZONE_ID in $ZONE_IDS; do
  SHORT_ID=$(echo $ZONE_ID | sed 's|/hostedzone/||')
  ZONE_NAME=$(aws route53 get-hosted-zone --id $SHORT_ID \
    --query "HostedZone.Name" --output text 2>/dev/null)
  echo -e "  Zone: ${ZONE_NAME} (${SHORT_ID})"
  aws route53 list-resource-record-sets \
    --hosted-zone-id $SHORT_ID \
    --max-items 20 \
    --query "ResourceRecordSets[*].[Name,Type,TTL,ResourceRecords[0].Value]" \
    --output table 2>/dev/null
done


# ── SECRETS MANAGER ───────────────────────────────────────────────────────────
subsection "SECRETS MANAGER"
for REGION in $REGIONS; do
  echo -e "\n${GREEN}[$REGION]${RESET} Secrets Manager Secrets"
  aws secretsmanager list-secrets \
    --region $REGION \
    --query "SecretList[*].[Name,LastChangedDate,LastAccessedDate,DeletedDate]" \
    --output table 2>/dev/null || echo "  (none or access denied)"
done


# =============================================================================
# HOW TO READ THE OUTPUT
# =============================================================================
section "HOW TO READ THE OUTPUT"
cat <<'GUIDE'

COLUMNS BY RESOURCE TYPE
─────────────────────────────────────────────────────────────────────────────
Transit Gateways         ID | State | OwnerAccountId | Name | CreatedTime
TGW Attachments          AttachmentId | ResourceType | ResourceId | State | Name
VPC Endpoints            EndpointId | Type(Gateway/Interface) | ServiceName | State | VpcId
NAT Gateways             NatGatewayId | State | VpcId | SubnetId | Name
Elastic IPs              AllocationId | PublicIp | AssociationId | InstanceId | Name
EC2 Instances            InstanceId | Name | Type | State | LaunchTime | AZ
EBS Volumes              VolumeId | State | SizeGB | Type | AttachedInstanceId | Name
Load Balancers           Name | Type(alb/nlb) | State | DNSName | CreatedTime
Target Groups            Name | Protocol | Port | TargetType | AttachedLBArn
RDS Instances            Identifier | Status | Class | Engine | Version | MultiAZ
RDS Snapshots            SnapshotId | DBIdentifier | Status | CreatedTime | SizeGB
WAF Web ACLs             Name | Id | ARN
Route 53 Zones           ZoneId | DomainName | IsPrivate | RecordCount
Route 53 Records         RecordName | Type | TTL | Value
Secrets Manager          Name | LastChanged | LastAccessed | DeletedDate

STATE VALUES TO KNOW
─────────────────────────────────────────────────────────────────────────────
EC2:  running=billed | stopped=EBS still billed | terminated=safe
EBS:  in-use=billed  | available=billed (unattached!) | deleting=safe
RDS:  available=billed | stopped=storage still billed | deleting=safe
NAT:  available=billed (~$1.08/day + data) | deleted=safe
EIP:  associated=no extra charge | unassociated=billed ($0.005/hr each)
LB:   active=billed (~$0.008/LCU-hr) | provisioning | active_impaired
TGW:  available=billed ($0.05/hr + $0.02/GB)

GUIDE


# =============================================================================
# HIGH-RISK ITEMS TO REVIEW BEFORE DELETE
# =============================================================================
section "HIGH-RISK ITEMS TO REVIEW BEFORE DELETE"
cat <<'RISKS'

  RESOURCE               RISK IF DELETED                         SAFE TO DELETE IF...
  ─────────────────────────────────────────────────────────────────────────────────────
  Transit Gateways       Breaks inter-VPC / on-prem routing      All attachments removed first
  TGW Attachments        Orphans routes in route tables           Routes cleaned up after
  VPC Endpoints          Apps lose private AWS service access     No traffic flowing through them
  NAT Gateways           Private subnet instances lose internet   Instances are stopped or terminated
  Elastic IPs            Floating IPs reassigned/lost             Confirmed unused / unassociated
  EC2 Instances          Instance store data PERMANENT LOSS       EBS snapshots taken first
  EBS Volumes            Data PERMANENTLY LOST                    Snapshot taken or data confirmed expendable
  Load Balancers         DNS breaks for all associated services   Target groups and DNS records updated
  Target Groups          LB health checks fail                    LB deleted or targets deregistered first
  RDS Instances          Database PERMANENTLY LOST                Final snapshot taken (check DeletionProtection)
  RDS Snapshots          Point-in-time restore lost               Source DB confirmed deleted and data not needed
  WAF Web ACLs           ALB/CloudFront loses protection          No ALB/CF distribution associated
  Route 53 Zones         DNS resolution fails for domain          All records reviewed; domain not in active use
  Route 53 Records       Service endpoints become unreachable     Downstream services confirmed decommissioned
  Secrets Manager        Apps referencing secret will break       No Lambda/ECS/EC2 actively reading it

  ORDER OF SAFE DELETION (bottom-up dependency order)
  ─────────────────────────────────────────────────────
  1.  WAF Web ACLs          (disassociate from ALB/CF first)
  2.  Route 53 Records      (remove before zone)
  3.  Route 53 Hosted Zones
  4.  Target Groups         (deregister targets first)
  5.  Load Balancers
  6.  RDS Instances         (take final snapshot first)
  7.  RDS Snapshots         (after confirming DB is gone)
  8.  EC2 Instances         (take EBS snapshot first if needed)
  9.  EBS Volumes           (after instance terminated)
  10. NAT Gateways          (after private instances stopped/terminated)
  11. TGW Attachments       (before deleting TGW)
  12. Transit Gateways
  13. VPC Endpoints
  14. Elastic IPs           (release only after confirmed unassociated)
  15. Secrets Manager       (after confirming no active consumers)

RISKS

echo -e "\n${GREEN}✔ Inventory complete. No resources were modified.${RESET}\n"
