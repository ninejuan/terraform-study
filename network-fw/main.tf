provider "aws" {
  region = "ap-northeast-2"
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# 2. 서브넷 (Public, Firewall)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"
}

# 3. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# 4. Network Firewall Policy
resource "aws_networkfirewall_rule_group" "block_ifconfig" {
  capacity = 100
  name     = "block-ifconfig"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
pass tcp any any -> any any (msg:"Allow all TCP"; sid:1;)
drop tcp any any -> any any (msg:"Block ifconfig.me"; content:"ifconfig.me"; sid:2;)
EOF
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "main-firewall-policy"

  firewall_policy {
    stateless_default_actions = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_ifconfig.arn
    }
  }
}

# 5. Network Firewall
resource "aws_networkfirewall_firewall" "main" {
  name                = "main-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.main.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }
}

# 6. 라우팅 테이블
## 퍼블릭 서브넷 → Firewall Endpoint
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

# Firewall endpoint ID는 생성 후 data source로 가져옴
data "aws_networkfirewall_firewall" "main" {
  name = aws_networkfirewall_firewall.main.name
}

# Firewall Endpoint로 라우팅
resource "aws_route" "public_to_firewall" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = data.aws_networkfirewall_firewall.main.firewall_status[0].sync_states["ap-northeast-2a"].attachment[0].endpoint_id
}

# 라우팅 테이블 연결
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
