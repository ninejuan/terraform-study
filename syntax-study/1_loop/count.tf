data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

### -----------------
### Count only loop
### -----------------
resource "aws_instance" "server-counts" {
  count = 3
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = var.public_subnet_id
  tags = {
    Name = "count0${count.index + 1}"
  }
}

### -----------------
### Array loop
### -----------------
# Instance type은 중간에 뭐가 들어가도 중지 후 수정, 시작하면 되지만 AMI 등의 경우는 삭제 후 재생성이 되기 때문에 Array를 통한 loop는 적절하지 않음.
# 또한, SG의 경우에도 마찬가지로 삭제 후 재생성이 되기 때문에 Array를 통한 loop는 적절하지 않음.
locals {
    instance_types = ["t3.micro", "t3.nano", "t3.small", "t3.medium"]
}

resource "aws_instance" "server-arrays" {
  count = length(local.instance_types)
  ami = data.aws_ami.amazon_linux.id
  instance_type = local.instance_types[count.index]

  subnet_id = var.public_subnet_id
  tags = {
    Name = "array0${count.index + 1}"
  }
}
