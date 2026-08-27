variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env_subfix" {
  description = "Environment suffix"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "tags_project" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
