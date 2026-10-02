variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "vm_size" { type = string }
variable "availability_zone" {
  type     = string
  default  = null
  nullable = true
}
variable "admin_ssh_public_key" { type = string }
variable "tags" { type = map(string) }
