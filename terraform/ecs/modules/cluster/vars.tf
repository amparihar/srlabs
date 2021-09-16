variable "app_name" {
  type = string
}
variable "stage_name" {
  type = string
}
variable "regionid" {
  type = string
}
variable "ecs_cluster_name" {
  type = string
}
variable "vpcid" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "alb_security_group_id" {
  type = string
}
variable "alb_dns_name" {
  type = string
}
variable "target_groups" {
  type = map(string)
}


# Verify supported task CPU and memory values for tasks that are hosted on Fargate 
variable "task_cpu" {
  type = map(string)
  default = {
    "front_end_microservice"        = "512"
  }
}
variable "task_memory" {
  type = map(string)
  default = {
    "front_end_microservice"        = "1024"
  }
}
variable "container_ports" {
  type = map(number)
  default = {
    "front_end_microservice"        = 80
  }
}

variable "container_images" {
  type = map(string)
  default = {
    front_end_microservice        = "aparihar/nginx-ecs-gs:latest"
  }
}
