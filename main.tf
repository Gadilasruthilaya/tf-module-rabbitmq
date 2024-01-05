resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id


  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.sg_subnet_cidr

  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "ssh"
    cidr_blocks = var.allow_ssh_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}



resource "aws_instance" "rabbitmq" {
  ami                    = data.aws_ami.example.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  subnet_id = var.subnet_id
  user_data     = templatefile("${path.module}/userdata.sh", {
    environment = var.env
    component = var.component
  })


  tags = merge({
    Name = "${var.component}-${var.env}"
  }, var.tags)

}


resource "aws_route53_record" "rabbitmq" {
  zone_id = var.zone_id
  name    = "${var.component}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.rabbitmq.private_ip]
}