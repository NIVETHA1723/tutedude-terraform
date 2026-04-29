# Part 1 Outputs
output "part1_public_ip" {
  description = "Public IP of the Part 1 EC2 instance"
  value       = module.part1.public_ip
}

output "part1_flask_url" {
  description = "URL for the Flask app in Part 1"
  value       = "http://${module.part1.public_ip}:5000"
}

output "part1_express_url" {
  description = "URL for the Express app in Part 1"
  value       = "http://${module.part1.public_ip}:3000"
}

# Part 2 Outputs
output "part2_backend_url" {
  description = "Public URL for the Flask backend in Part 2"
  value       = "http://${module.part2.backend_public_ip}:5000"
}

output "part2_frontend_url" {
  description = "Public URL for the Express frontend in Part 2"
  value       = "http://${module.part2.frontend_public_ip}:3000"
}

# Part 3 Outputs
output "part3_alb_dns" {
  description = "DNS name of the ALB in Part 3"
  value       = module.part3.alb_dns_name
}
