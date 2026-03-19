# route to sao paulo via TGW
resource "aws_route" "tokyo_to_sao_paulo" {
  route_table_id         = aws_route_table.tokyo_private_rt.id
  destination_cidr_block = var.sao_paulo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tokyo_tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_vpc_attachment]
}

# route to osaka via TGW (failover)
resource "aws_route" "tokyo_to_osaka" {
  count = var.osaka_tgw_id != "" ? 1 : 0

  route_table_id         = aws_route_table.tokyo_private_rt.id
  destination_cidr_block = var.osaka_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tokyo_tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_vpc_attachment]
}
