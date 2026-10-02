variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = list(string) }
variable "aks_subnet_address_prefixes" { type = list(string) }
variable "node_subnet_address_prefixes" { type = list(string) }
variable "runner_subnet_address_prefixes" { type = list(string) }
variable "tags" { type = map(string) }
