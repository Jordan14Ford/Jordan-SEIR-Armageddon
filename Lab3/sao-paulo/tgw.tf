# transit gateway - accepts peering from tokyo

resource "aws_ec2_transit_gateway" "sao_paulo_tgw" {
  description                     = "Sao Paulo Transit Gateway for Lab 3"
  amazon_side_asn                 = var.sao_paulo_tgw_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = {
    Name = "${var.project}-sao-paulo-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "sao_paulo_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.sao_paulo_tgw.id
  vpc_id             = aws_vpc.sao_paulo_vpc.id
  subnet_ids         = [aws_subnet.sao_paulo_private_1.id, aws_subnet.sao_paulo_private_2.id]

  dns_support = "enable"

  tags = {
    Name = "${var.project}-sao-paulo-vpc-attachment"
  }
}

# accept the peering from tokyo
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_tokyo_peering" {
  transit_gateway_attachment_id = data.terraform_remote_state.tokyo.outputs.tokyo_tgw_peering_attachment_id

  tags = {
    Name = "${var.project}-accept-tokyo-peering"
  }
}

# route to tokyo
resource "aws_ec2_transit_gateway_route" "to_tokyo" {
  destination_cidr_block         = var.tokyo_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.sao_paulo_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.accept_tokyo_peering.transit_gateway_attachment_id
}
