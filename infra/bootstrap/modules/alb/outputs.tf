output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}