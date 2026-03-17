# =============================================================================
# LAB 3 - SAO PAULO VPC ROUTES
# File: lab3/sao-paulo/routes.tf
# Region: sa-east-1 (Sao Paulo)
# Purpose: Adds the route from Sao Paulo VPC to Tokyo VPC via the TGW.
#
# ROUTE FLOW:
#   Sao Paulo EC2 -> private route table -> TGW -> TGW peering -> Tokyo VPC
#
# WHY A SEPARATE FILE?
#   Routes depend on the TGW being created first. Keeping them in a separate
#   file makes the dependency chain clear and allows for easier troubleshooting.
#
# WHAT THIS ROUTE DOES:
#   Traffic destined for 10.0.0.0/16 (Tokyo VPC) is sent to the Sao Paulo TGW.
#   The TGW then forwards it through the peering attachment to Tokyo.
#   This is how the Flask app reaches the Tokyo RDS instance.
# =============================================================================


# -----------------------------------------------------------------------------
# ROUTE TO TOKYO VIA TGW
# This route is added to the private route table. When EC2 instances try to
# reach the Tokyo RDS (which has an IP in 10.0.0.0/16), this route directs
# that traffic to the TGW instead of the NAT Gateway.
#
# IMPORTANT: The route table already has a 0.0.0.0/0 -> NAT route (in main.tf).
#            This 10.0.0.0/16 -> TGW route is more specific, so it takes
#            precedence for Tokyo-bound traffic.
# -----------------------------------------------------------------------------
resource "aws_route" "sao_paulo_to_tokyo" {
  route_table_id         = aws_route_table.sao_paulo_private_rt.id
  destination_cidr_block = var.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.sao_paulo_tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.sao_paulo_vpc_attachment]
}
