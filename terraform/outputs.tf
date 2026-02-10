output "frontend" {
  description = "Public IP address of frontend instance"
  value       = aws_instance.ironhack-proj1-vote-result-vijaya.public_ip
}

output "backend" {
  description = "Private IP address of backend instance"
  value       = aws_instance.ironhack-proj1-redis-worker-vijaya.private_ip
}


output "database" {
  description = "Private IP address of database instance"
  value       = aws_instance.ironhack-proj1-postgres-db-vijaya.private_ip
}