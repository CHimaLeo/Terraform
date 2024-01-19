variable "aws_acces_key" {
  type = string
  default = "default"
}

variable "aws_secret_key" {
  type = string
  default = "default"
}

variable "key_name" {
  type = string
  default = "default"
}

variable "aws_ami_mongo" {
  type = string
  default = "ami-0a5b5257c1bff80b9"
}

variable "aws_ami_app" {
  type = string
  default = "ami-032b12c29be4ccf03"
}

variable "ip_mongo" {
  type = string
  default = "10.0.1.10"
}

variable "ip_app" {
  type = list(string)
  default = ["10.0.2.11", "10.0.2.12"]
}