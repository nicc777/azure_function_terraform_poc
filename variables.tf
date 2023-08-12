variable "owner" {
  type = string
  default = "nicc777"
}

variable "project_name" {
  type = string
  default = "timeeventtest"
}

variable "location" {
  type = string
  default = "West Europe"
}

variable "tags" {
  type        = map(string)
  default     = {}
}