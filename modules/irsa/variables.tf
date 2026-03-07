variable "role_name" {
  description = "Name of the IAM role for the service account"
  type        = string
}

variable "role_description" {
  description = "Description for the IAM role"
  type        = string
  default     = "IRSA role"
}

variable "role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 and 43200 seconds."
  }
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider"
  type        = string
}

variable "service_accounts" {
  description = "List of Kubernetes service accounts to bind to this role"
  type = list(object({
    namespace = string
    name      = string
  }))

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "At least one service account must be specified."
  }
}

variable "assume_role_condition_test" {
  description = "IAM condition operator for the OIDC trust. Use StringEquals for single SA, StringLike for wildcards"
  type        = string
  default     = "StringEquals"

  validation {
    condition     = contains(["StringEquals", "StringLike"], var.assume_role_condition_test)
    error_message = "Condition test must be StringEquals or StringLike."
  }
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "JSON-encoded inline IAM policy to attach to the role"
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy for the role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}
