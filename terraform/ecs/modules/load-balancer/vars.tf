variable "app_name" {
  type = string
}
variable "stage_name" {
  type = string
}
variable "create_alb" {
  type    = bool
  default = true
}
variable "vpcid" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "listener_path_patterns" {
  type = map(list(string))
  default = {
    "front_end_microservice" = ["/*"]
  }
}
variable "target_group_health_check_path" {
  type = map(string)
  default = {
    "front_end_microservice" = "/index.html"
  }
}
