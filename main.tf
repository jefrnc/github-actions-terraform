provider "aws" {
	region = "eu-west-3"
}
 
resource "aws_instance" "example" {
	ami = "ami-0357d42faf6fa582f"
	instance_type = "t2.micro"
 
	user_data = <<-EOF
	        #!/bin/bash
		    sudo yum update -y
		    sudo yum -y install httpd -y
		    sudo service httpd start
		    echo "Hello world from EC2 $(hostname -f)" > /var/www/html/index.html
		    EOF
				
	tags = {
		Name = "My first EC2 using Terraform"
	}
	vpc_security_group_ids = [aws_security_group.instance.id]
}
 
resource "aws_security_group" "instance" {
	name = "terraform-tcp-security-group"
 
	ingress {
		from_port = 80
		to_port = 80
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