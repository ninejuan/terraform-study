module "loop" {
    source = "./1_loop"
    public_subnet_id = aws_subnet.public.id

    depends_on = [aws_subnet.public]
}