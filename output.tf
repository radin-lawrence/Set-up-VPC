output "my_vpc" {
value = aws_vpc.vpc.id 
}
output "public" {
 value = [aws_subnet.public[0].id,aws_subnet.public[1].id,aws_subnet.public[2].id]
}
