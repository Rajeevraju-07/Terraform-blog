provider "aws" {
  region     = "us-west-1"
  access_key = "AKIATVX2F23E3KJYQXX4"
  secret_key = "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"
}

# # 1. Create vpc

resource "aws_vpc" "prod-vpc" {
   cidr_block = "10.0.0.0/16"
   tags = {
     Name = "production"
   }
 }

# # 2. Create Internet Gateway

 resource "aws_internet_gateway" "gw" {
   vpc_id = aws_vpc.prod-vpc.id

 }

# # 3. Create Custom Route Table

 resource "aws_route_table" "prod-route-table" {
   vpc_id = aws_vpc.prod-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
   }

   route {
     ipv6_cidr_block = "::/0"
     gateway_id      = aws_internet_gateway.gw.id
   }

   tags = {
     Name = "Prod"
   }
 }

 # 4. Create a Subnet 

 resource "aws_subnet" "subnet-1" {
   vpc_id            = aws_vpc.prod-vpc.id
   cidr_block        = "10.0.4.0/24"
   availability_zone = "us-west-1b"

   tags = {
     Name = "prod-subnet1"
   }
 }

 # 5. Associate subnet with Route Table
 resource "aws_route_table_association" "a" {
   subnet_id      = aws_subnet.subnet-1.id
   route_table_id = aws_route_table.prod-route-table.id
 }

# # 6. Create Security Group to allow port 22,80,443
 resource "aws_security_group" "allow_web" {
   name        = "allow_web_traffic"
   description = "Allow Web inbound traffic"
   vpc_id      = aws_vpc.prod-vpc.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]  
   }
   ingress {
     description = "HTTP"
     from_port   = 8080
     to_port     = 8080
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }

   tags = {
     Name = "allow_web"
   }
 }

# # 7. Create a network interface with an ip in the subnet that was created in step 4

 resource "aws_network_interface" "web-server-nic" {
   subnet_id       = aws_subnet.subnet-1.id
   private_ips     = ["10.0.4.50"]
   security_groups = [aws_security_group.allow_web.id]
 }

 # 8. Assign an elastic IP to the network interface created in step 7

 resource "aws_eip" "one" {
   vpc                       = true
   network_interface         = aws_network_interface.web-server-nic.id
   associate_with_private_ip = "10.0.4.50"
   depends_on                = [aws_internet_gateway.gw]
 }

 output "server_public_ip" {
   value = aws_eip.one.public_ip
 }

# # 9. Create Ubuntu server and install/enable apache2

 resource "aws_instance" "web-server-instance" {
   ami               = "ami-0dc5e9ff792ec08e3"
   instance_type     = "t2.micro"
   availability_zone = "us-west-1b"
   key_name          = "newkey"
    
   
   network_interface {
     device_index         = 0
     network_interface_id = aws_network_interface.web-server-nic.id
   }

   user_data = "${file("script.sh")}"
   

    tags = {
     Name = "web-server"
   }
 }
  resource "aws_codecommit_repository" "test" {

repository_name = "Repo"

description = "This is the Sample App Repository"

} 

    





   
resource "local_file" "foo" {
    content  = file("text.txt")
    filename = "jenkinsfile"
}

resource "local_file" "job" {
    content  = file("sam.xml")
    filename = "job.xml"
}

resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = <<EOT
    mkdir tst
    cd tst
    git clone ${aws_codecommit_repository.test.clone_url_http}
    cd ..
    mv ${local_file.foo.filename} tst/Repo/
    mv ${local_file.job.filename} tst/Repo/
    cd tst/Repo/
    git add ${local_file.foo.filename}
    git add ${local_file.job.filename}
    git commit -m "test commit"
    git push
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
} 

