output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "security_group_id" {
  value = aws_security_group.alb.id
}
