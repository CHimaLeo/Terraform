#Creación de VPC 
resource "aws_vpc" "vpc_terraform" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "vpc-terraform"
  }
}

#creación de Subredes
resource "aws_subnet" "subnets_terraform" {
  count = 2
  vpc_id = aws_vpc.vpc_terraform.id
  cidr_block = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone_id = element(["use1-az1", "use1-az2"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-terraform${count.index + 1}"
  }
}

#Creación de Tabla de enrutamiento
resource "aws_route_table" "route_terraform" {
  vpc_id = aws_vpc.vpc_terraform.id
  tags = {
    Name = "route-terraform"
  }
}

#Gateway
resource "aws_internet_gateway" "gateway_terraform" {
  vpc_id = aws_vpc.vpc_terraform.id
  tags = {
    Name = "geteway-terraform"
  }
}
#Enrutamiento
resource "aws_route_table_association" "router_terraform" {
  count = 2
  subnet_id = aws_subnet.subnets_terraform[count.index].id
  route_table_id = aws_route_table.route_terraform.id
}

resource "aws_route" "aws_route_terraform" {
  route_table_id = aws_route_table.route_terraform.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gateway_terraform.id
}

#Grupo de seguridad
resource "aws_security_group" "security_group" {
  name = "security-terraform"
  description = "Terraform"
  vpc_id = aws_vpc.vpc_terraform.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/16"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/16"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/16"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Mongo
resource "aws_instance" "mongo_server" {
  ami = var.aws_ami_mongo
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_id = aws_subnet.subnets_terraform[0].id
  private_ip = var.ip_mongo
  tags = {
    Name = "MongoDB-Server"
  }
}

#web
resource "aws_instance" "web_server" {
  count = 2
  ami = var.aws_ami_app
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.subnets_terraform[1].id
  private_ip = element(var.ip_app, count.index)
  vpc_security_group_ids = [ aws_security_group.security_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "Web-Server${count.index + 1}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("")
    host = self.public_ip
  }

provisioner "file" {
    source = "install_mongo.sh"
    destination = "/home/install_mongo.sh"
  }

  provisioner "file" {
    source = "index.js"
    destination = "/tmp/index.js"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo ./install_mongo.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
        "sudo cp /tmp/index.js /var/www/MyApp/index.js"
    ]
  }

  provisioner "remote-exec" {
    inline = [
        "pm2 start /var/www/MyApp/index.js -f"
    ]
  }
}

resource "aws_lb" "balanceador_terraform" {
  name = "Balanceador-terraform"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.security_group.id]
  subnets = aws_subnet.subnets_terraform[*].id
  enable_deletion_protection = false
}
 
resource "aws_lb_target_group" "targer_grup_terraform" {
  name = "Terraform-tareger-grup"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.vpc_terraform.id

  health_check {
    path = "/"
    interval = 30
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_lb_listener" "balance_listener_terraform" {
  load_balancer_arn = aws_lb.balanceador_terraform.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.targer_grup_terraform.arn
  }
}

resource "aws_lb_target_group_attachment" "targer_grup_terraform_att" {
  count = 2
  target_group_arn = aws_route_table.route_terraform.arn
  target_id = aws_instance.web_server[count.index].private_ip
  port = 80
}