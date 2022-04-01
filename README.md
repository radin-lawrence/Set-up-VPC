
# AWS VPC using terraform

In this article, I will show you how to create a VPC along with Subnets, Internet Gateway, NAT Gateways, and Route Tables. We will be making 1 VPC with 6 Subnets: 3 Private and 3 Public

## Terraform Features

- The human-readable configuration language helps you write infrastructure code quickly.
- Friendly custom syntax, but also has support for JSON.
- AWS informations are defined using tfvars file and can easily changed
## Terraform Installation

- Create an IAM user on your AWS console that has "Access key - Programmatic access" with the policy permission of the required resource.
- Download Terraform, click here [Terraform](https://www.terraform.io/downloads)
-  Install Terraform,
 Use the following command to install Terraform

 ```bash
 $ wget https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_amd64.zip
 $ unzip terraform_1.1.7_linux_amd64.zip 
 $ ll
 total 80136
 -rwxr-xr-x 1 ec2-user ec2-user 63262720 Mar  2 19:17 terraform
 -rw-rw-r-- 1 ec2-user ec2-user 18795309 Mar  2 19:32 terraform_1.1.7_linux_amd64.zip
$ sudo mv terraform /usr/local/bin/
$ terraform version
 Terraform v1.1.7
 on linux_amd64
```

**Create project Directory**

```bash
$ mkdir -p /var/terraform/vpc
$ cd /var/terraform/vpc
```



##  AWS VPC Creation
An AWS VPC is a single network that allows you to launch AWS services within a single isolated network. 

```bash
resource "aws_vpc"  "vpc" {
   
  cidr_block           = var.cidr_blk
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
    
  tags = {
    Name    = var.project
  }
    
}
```
instance_tenancy - A tenancy option for instances launched into the VPC. Default is default, which makes your instances shared on the host. Using either of the other options (dedicated or host) costs at least $2/hr.

## Aws public subnet creation
The count is a meta-argument defined by the Terraform language. Here I'm using the count as 3, which will create three public subnets of the resource. 

```bash
resource "aws_subnet" "public" {
  
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_blk,var.subnet,count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-${count.index+1}"
  
  }
}
```

map_public_ip_on_launch: This is so important. The only difference between private and public subnet is this line. If it is true, it will be a public subnet, otherwise private.

## Creating route table for public subnet
Creates a custom route table for public subnet. public subnet can reach to the internet by using this.
```bash
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project}-public"
  }
}
```

## Creating Internet gateway

Creates an Internet Gateway and attaches it to the VPC to allow traffic within the VPC to be reachable by the outside world, which means enables your VPC to connect to the internet

```bash
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}"
  }
}
```

## Route table association of public subnet

```bash
resource "aws_route_table_association" "public" {
  count	         = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

## Aws private subnet creation
The instances in the public subnet can send outbound traffic directly to the internet, whereas the instances in the private subnet can't. Instead, the instances in the private subnet can access the internet by using a network address translation (NAT) gateway that resides in the public subnet. 
```bash
resource "aws_subnet" "private" {

  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_blk,var.subnet,"${count.index+3}")
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project}-private-${count.index+1}"
  }
}
```

## Create Elastic IP 

```bash
resource "aws_eip" "elastic" {
  
  vpc      = true
tags = {
 Name = "${var.project}"
 }
}

```

## Creating Nat gateway 
Creates a NAT Gateway to enable private subnets to reach out to the internet without needing an externally routable IP address assigned to each resource.

```bash
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.private[1].id

  tags = {
    Name = "${var.project}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

```

##  Creating route table for private subent 

```bash
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project}-private"
  }
}
```

## Route table association

```bash
resource "aws_route_table_association" "private" {
  count	         = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

**Terraform Validation**

This will check for any errors on the source code

```bash
terrafom validate
```

**Terraform Plan**

Creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
```bash
terraform plan -var-file="variable.tfvars"
```

**Terraform apply**

Executes the actions proposed in a Terraform plan.
```bash
terraform apply -var-file="variable.tfvars"
```

## Conclusion

Here is a simple document on how to set up VPC along with Subnets, Internet Gateway, NAT Gateways, and Route Tables

## Connect with Me

### ⚙️ Connect with Me
<p align="center">
<a href="https://www.linkedin.com/in/radin-lawrence-8b3270102/"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"/></a>
<a href="mailto:radin.lawrence@gmail.com"><img src="https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white"/></a>
