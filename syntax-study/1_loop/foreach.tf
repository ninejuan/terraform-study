resource "aws_instance" "server-fe" {
    for_each = {
        windows = {
            ami = data.aws_ami.windows_10.id
            instance_type = "t3.micro"
        }
        linux = {
            ami = data.aws_ami.amazon_linux_2023.id
            instance_type = "t3.micro"
        }
    }

    ami = each.value.ami
    instance_type = each.value.instance_type
    tags = {
        Name = "foreach0${each.key}"
    }

    subnet_id = var.public_subnet_id
}