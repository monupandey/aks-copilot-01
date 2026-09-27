variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_id" { type = string }
variable "kubernetes_version" {
  type     = string
  nullable = true
}
variable "subnet_id" { type = string }
variable "service_cidr" { type = string }
variable "dns_service_ip" { type = string }
variable "admin_group_object_ids" { type = list(string) }
variable "system_node_vm_size" { type = string }
variable "user_node_pools" {
  type = map(object({
    vm_size   = string
    min_count = number
    max_count = number
    zones     = optional(list(string), [])
  }))
}
variable "github_repository" { type = string }
variable "github_branch" { type = string }
variable "tags" { type = map(string) }
