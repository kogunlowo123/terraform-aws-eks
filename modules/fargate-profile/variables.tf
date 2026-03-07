variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "name" {
  description = "Name of the Fargate profile"
  type        = string
}

variable "pod_execution_role_arn" {
  description = "ARN of the IAM role for Fargate pod execution"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Fargate pods"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required for Fargate profiles."
  }
}

variable "selectors" {
  description = "List of Fargate profile selectors with namespace and optional labels"
  type = list(object({
    namespace = string
    labels    = optional(map(string), {})
  }))

  validation {
    condition     = length(var.selectors) > 0
    error_message = "At least one selector is required."
  }
}

variable "tags" {
  description = "Tags to apply to the Fargate profile"
  type        = map(string)
  default     = {}
}
