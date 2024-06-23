provider "aws" {
  region = us-west-2
}
resource "aws_vpc" "customizevpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    name = "strapi-app-vpc"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id            = aws_vpc.customizevpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_internet_gateway" "customizegw" {
  vpc_id = aws_vpc.customizevpc.id
  tags = {
    Name = "customizegw"
  }
}



resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.customizevpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.customizegw.id
  }
}


resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}
resource "aws_security_group" "strapisg" {
  vpc_id      = aws_vpc.customizevpc.id
  description = "This is for strapy application"
  ingress {
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
  ingress {

    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sg-strapi"
  }

}

resource "aws_instance" "strapi-ec2" {
  ami                         = "ami-03c983f9003cb9cd1"
  availability_zone = "us-west-2a"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.strapisg.id]
  subnet_id                   = aws_subnet.publicsubnet.id
  key_name                    = "strapikey"
  associate_public_ip_address = true
  tags = {
    Name = "strapi-ec2"
  }
}

resource "null_resource" "example" {

    provisioner "remote-exec" {
      connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa") 
      host        = aws_instance.strapi-ec2.public_ip
    }
    inline = [
      "sudo apt-get update",
      "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo npm install -g pm2",
      "cd /srv",
      "sudo git clone https://github.com/PearlThoughts-DevOps-Internship/strapi",
      "sudo chown -R ubuntu:ubuntu /srv/strapi",
      "sudo chmod -R 755 /srv/strapi",
      "cd /srv/strapi",
      "git checkout -f surabhi-prod",
      "sudo npm install",
      "pm2 start npm --name strapi -- run develop",
      "pm2 save"
    ]
}
 depends_on = [
    aws_instance.strapi-ec2
  ]
  }
