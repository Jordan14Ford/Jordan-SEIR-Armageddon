# osaka outputs

output "osaka_vpc_id" {
  value = aws_vpc.osaka_vpc.id
}

output "osaka_tgw_id" {
  value = aws_ec2_transit_gateway.osaka_tgw.id
}

output "osaka_alb_dns" {
  value = aws_lb.osaka_alb.dns_name
}

output "osaka_ec2_id" {
  value = aws_instance.osaka_app.id
}

output "osaka_private_rt_id" {
  value = aws_route_table.osaka_private_rt.id
}

output "osaka_tgw_peering_attachment_id" {
  value = var.tokyo_tgw_id != "" ? aws_ec2_transit_gateway_peering_attachment.osaka_to_tokyo[0].id : "not created - tokyo_tgw_id not set"
}
