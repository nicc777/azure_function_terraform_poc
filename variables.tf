variable "owner" {
  type = string
  default = "nico"
}

variable "project_name" {
  type = string
  default = "time-event-test"
}

variable "location" {
  type = string
  default = "West Europe"
}

variable "tags" {
  type        = map(string)
  default     = {}
}