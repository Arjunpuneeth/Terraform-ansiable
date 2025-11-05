# The aws_instance resource needs to be updated to use the dynamic key_name
resource "aws_instance" "web" {
  ami               = "ami-02d26659fd82cf299"
  instance_type     = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  # Reference the dynamic key_name here
  key_name          = aws_key_pair.pem_file.key_name 
  tags = {
    Name = "JenkinsServer"
  }
  user_data = file("script.sh")
}


resource "aws_security_group" "allow_tls" {
  # Change name to be unique per build
  name        = "allow_tls-${var.build_suffix}" 
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = "vpc-0bd2d8380dd4df810"

  tags = {
    Name = "allow_tls-${var.build_suffix}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_allow_all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6_allow_all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"  # <<< REPLACE with your Jenkins server's static IP/CIDR (e.g., 1.2.3.4/32)
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Allow SSH from Jenkins/Ansible"
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
# Public key

# Public key
resource "aws_key_pair" "pem_file" {
  # Change key_name to be unique per build
  key_name   = "pem_file-${var.build_suffix}" 
  public_key = tls_private_key.rsa.public_key_openssh
}

# Private key generator (required for aws_key_pair and local_file resources)
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This resource is what you need to reference
resource "local_file" "pem_file" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "pem_file.pem" # The filename should match the output
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ssh_private_key_path" {
  description = "Local file path of the private SSH key"
  # This references the local_file resource where the key is saved
  value       = local_file.pem_file.filename
}

variable "build_suffix" {
  description = "A unique identifier (like Jenkins BUILD_NUMBER) to suffix resource names."
  type        = string
  default     = ""
}