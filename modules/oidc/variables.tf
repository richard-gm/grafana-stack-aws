variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env_subfix" {
  description = "Environment suffix"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "tags_project" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
