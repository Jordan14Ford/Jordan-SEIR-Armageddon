# osaka transit gateway - for connecting to tokyo

resource "aws_ec2_transit_gateway" "osaka_tgw" {
  description                     = "Osaka TGW for Tokyo failover"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  amazon_side_asn                 = 64514  # tokyo=64512, sao_paulo=64513, osaka=64514

  tags = {
    Name = "${var.project}-osaka-tgw"
  }
}

# attach osaka VPC to osaka TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "osaka_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.osaka_tgw.id
  vpc_id             = aws_vpc.osaka_vpc.id
  subnet_ids         = [aws_subnet.osaka_private_1.id, aws_subnet.osaka_private_2.id]

  tags = {
    Name = "${var.project}-osaka-vpc-attachment"
  }
}

# peering attachment to tokyo TGW
# tokyo TGW must accept this - see tokyo/tgw.tf for accepter resource
resource "aws_ec2_transit_gateway_peering_attachment" "osaka_to_tokyo" {
  count = var.tokyo_tgw_id != "" ? 1 : 0

  transit_gateway_id      = aws_ec2_transit_gateway.osaka_tgw.id
  peer_transit_gateway_id = var.tokyo_tgw_id
  peer_region             = "ap-northeast-1"  # tokyo

  tags = {
    Name = "${var.project}-osaka-tokyo-peering"
  }
}

# TGW route table - route tokyo traffic through peering
resource "aws_ec2_transit_gateway_route" "osaka_to_tokyo_route" {
  count = var.tokyo_tgw_id != "" ? 1 : 0

  destination_cidr_block         = var.tokyo_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.osaka_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.osaka_to_tokyo[0].id

  depends_on = [aws_ec2_transit_gateway_peering_attachment.osaka_to_tokyo]
}
