variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "name" {
  description = "Name of the node group"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["m5.large"]
}

variable "capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 33
}

variable "labels" {
  description = "Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for EBS volume encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
