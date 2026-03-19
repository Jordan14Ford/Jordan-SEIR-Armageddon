# transit gateway
# apply tokyo first, then sao paulo, then come back and add the peering

resource "aws_ec2_transit_gateway" "tokyo_tgw" {
  description     = "Lab 3 Tokyo TGW"
  amazon_side_asn = 64512  # sao paulo uses 64513

  auto_accept_shared_attachments = "enable"

  tags = {
    Name   = "${var.project}-tokyo-tgw"
    Region = "ap-northeast-1"
  }
}

# attach VPC to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  vpc_id             = aws_vpc.tokyo_vpc.id

  subnet_ids = [
    aws_subnet.tokyo_private_1.id, # ap-northeast-1a
    aws_subnet.tokyo_private_2.id  # ap-northeast-1c
  ]

  tags = {
    Name = "${var.project}-tokyo-tgw-vpc-attachment"
  }
}

# peering to sao paulo - need to fill in sao_paulo_tgw_id after deploying sao paulo
resource "aws_ec2_transit_gateway_peering_attachment" "tokyo_to_sao_paulo" {
  transit_gateway_id      = aws_ec2_transit_gateway.tokyo_tgw.id
  peer_transit_gateway_id = var.sao_paulo_tgw_id
  peer_region             = "sa-east-1"

  tags = {
    Name = "${var.project}-tokyo-to-sao-paulo-peering"
    Side = "initiator"
  }
}

# accept peering from osaka (osaka initiates, tokyo accepts)
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "osaka_peering_accepter" {
  count = var.osaka_tgw_id != "" ? 1 : 0

  transit_gateway_attachment_id = var.osaka_peering_attachment_id

  tags = {
    Name = "${var.project}-osaka-peering-accepted"
    Side = "accepter"
  }
}

# TGW route to osaka
resource "aws_ec2_transit_gateway_route" "tokyo_to_osaka_route" {
  count = var.osaka_tgw_id != "" ? 1 : 0

  destination_cidr_block         = var.osaka_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tokyo_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = var.osaka_peering_attachment_id
}
