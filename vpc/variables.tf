variable "vpc_cidr" {
  default = "10.101.0.0/16"
}

variable "env" {
  default = "dev"
}

variable "public_subnet_cidrs" {
  default = [
      "10.101.1.0/24",
      "10.101.2.0/24",
      "10.101.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  default = [
      "10.101.11.0/24",
      "10.101.12.0/24",
      "10.101.13.0/24"
  ]
}
