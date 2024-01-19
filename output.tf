output "momgodb_serever_ip" {
  value = aws_instance.mongo_server.public_ip
}

output "app_serever_ip" {
  value = [for instance in aws_instance.web_server : instance.public_ip]
}