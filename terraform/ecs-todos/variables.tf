variable "app_name" {
  type    = string
  default = "mytodos"
}
variable "stage_name" {
  type    = string
  default = "sr-vlabs"
}

variable "aws_region" {
  type    = string
  default = "ohio"
}
variable "aws_regions" {
  type = map(string)
  default = {
    ohio = "us-east-2"
  }
}
variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS Cluster (up to 255 letters, numbers, hyphens, and underscores)"
  default     = "mytodos-cluster"
  validation {
    condition     = length(var.ecs_cluster_name) > 0
    error_message = "Cluster Name is required."
  }
}
variable "jwt_access_token" {
  type = string
}
