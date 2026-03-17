# osaka routes - add tokyo route to private route table

resource "aws_route" "osaka_to_tokyo" {
  count = var.tokyo_tgw_id != "" ? 1 : 0

  route_table_id         = aws_route_table.osaka_private_rt.id
  destination_cidr_block = var.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.osaka_tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.osaka_vpc_attachment]
}
