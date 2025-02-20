# provider "aws" {
#   region = "us-east-1"
# }

# locals {
#   csv_files = ["prefix_list5-short.csv"]

#   # Read CSV files into a structured map
#   prefix_lists = {
#     for file in local.csv_files :
#     trimsuffix(file, ".csv") => [for line in split("\n", file("${path.module}/${file}")) :
#       {
#         cidr        = element(split(",", line), 0)
#         description = element(split(",", line), 1)
#       } if length(trimspace(line)) > 0 && !startswith(line, "cidr") # Ignore header
#     ]
#   }
# }

# resource "aws_ec2_managed_prefix_list" "prefix_lists" {
#   for_each       = local.prefix_lists
#   name           = each.key
#   address_family = "IPv4"
#   max_entries    = 1000 # Allow space for future entries

#   tags = {
#     Name = each.key
#   }
# }

# resource "aws_ec2_managed_prefix_list_entry" "prefix_list_entries" {
#   for_each = { for entry in flatten([
#     for pl_name, entries in local.prefix_lists : [
#       for i, entry in entries : {
#         key     = "${pl_name}-${i}" # Unique key
#         pl_name = pl_name
#         cidr    = entry.cidr
#         desc    = entry.description
#         batch   = floor(i / 100) # Create batches of 100
#       }
#     ]
#   ]) : "${entry.pl_name}-${entry.batch}-${entry.key}" => entry }

#   prefix_list_id = aws_ec2_managed_prefix_list.prefix_lists[each.value.pl_name].id
#   cidr           = each.value.cidr
#   description    = each.value.desc
# }

# resource "aws_security_group" "example_sg" {
#   name        = "example-security-group"
#   description = "Security group with two inbound rules"
#   vpc_id      = "vpc-0055bc6bbdf42ef35" # Replace with your actual VPC ID

#   # Inbound Rule 1: Allow SSH (Port 22) from a specific IP
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["172.31.0.0/16"] # Replace with your allowed IP range
#     description = "Allow SSH access"
#   }

#   # Inbound Rule 2: Allow HTTP (Port 80) from anywhere
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Open to all
#     description = "Allow HTTP traffic"
#   }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"] # Open to all
  #   description = "team-b"
  # }

#   ingress {
#     from_port   = 1433
#     to_port     = 1433
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Open to all
#     description = "b"
#   }

#   # Outbound Rule: Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "example-sg"
#   }
# }

provider "aws" {
  region = "us-east-1"
}

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description = "Single VPC Transit Gateway"
  amazon_side_asn = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}

# Create Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = { Name = "TGW-Route-Table" }
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  subnet_ids = ["subnet-02525c0542740b69f", "subnet-0373840c25c3144a9"]  # Replace with actual subnet IDs
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id = "vpc-084a8e858f8f1774d"  # Replace with actual VPC ID
}

# Associate TGW Route Table with the VPC Attachment
resource "aws_ec2_transit_gateway_route_table_association" "vpc_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}
