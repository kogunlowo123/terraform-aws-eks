################################################################################
# Cluster Configuration
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[5-9]|[3-9][0-9])$", var.cluster_version))
    error_message = "Cluster version must be a valid EKS Kubernetes version (1.25+)."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for high availability."
  }
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the EKS control plane ENIs; defaults to subnet_ids."
  type        = list(string)
  default     = []
}

################################################################################
# Cluster Endpoint Configuration
################################################################################

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint access."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint access."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries must be valid CIDR blocks."
  }
}

################################################################################
# Encryption Configuration
################################################################################

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets using KMS."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of an existing KMS key for cluster encryption; a new key is created if null."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN."
  }
}

################################################################################
# Logging Configuration
################################################################################

variable "cluster_log_types" {
  description = "List of control plane logging types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Valid log types are: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs in CloudWatch."
  type        = number
  default     = 90

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cluster_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

################################################################################
# Managed Node Groups
################################################################################

variable "managed_node_groups" {
  description = "Map of managed node group configurations."
  type = map(object({
    name           = string
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    ami_type       = optional(string, "AL2_x86_64")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    subnet_ids = optional(list(string), [])
    tags       = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.managed_node_groups :
      v.min_size <= v.desired_size && v.desired_size <= v.max_size
    ])
    error_message = "For each node group: min_size <= desired_size <= max_size must be satisfied."
  }

  validation {
    condition = alltrue([
      for k, v in var.managed_node_groups :
      contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }

  validation {
    condition = alltrue([
      for k, v in var.managed_node_groups :
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD"], v.ami_type)
    ])
    error_message = "AMI type must be a valid EKS AMI type."
  }
}

################################################################################
# Fargate Profiles
################################################################################

variable "fargate_profiles" {
  description = "Map of Fargate profile configurations."
  type = map(object({
    name = string
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    subnet_ids = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.fargate_profiles :
      length(v.selectors) > 0
    ])
    error_message = "Each Fargate profile must have at least one selector."
  }
}

################################################################################
# Cluster Add-ons
################################################################################

variable "cluster_addons" {
  description = "Map of EKS cluster add-on configurations."
  type = map(object({
    addon_version        = optional(string)
    resolve_conflicts    = optional(string, "OVERWRITE")
    configuration_values = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.cluster_addons :
      contains(["OVERWRITE", "NONE", "PRESERVE"], v.resolve_conflicts)
    ])
    error_message = "resolve_conflicts must be OVERWRITE, NONE, or PRESERVE."
  }
}

################################################################################
# IRSA
################################################################################

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA) via OIDC provider."
  type        = bool
  default     = true
}

################################################################################
# Access Entries (EKS Access API)
################################################################################

variable "access_entries" {
  description = "Map of EKS access entries for cluster authentication."
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), [])
    type              = optional(string, "STANDARD")
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string), [])
      })
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.access_entries :
      contains(["STANDARD", "FARGATE_LINUX", "EC2_LINUX", "EC2_WINDOWS"], v.type)
    ])
    error_message = "Access entry type must be STANDARD, FARGATE_LINUX, EC2_LINUX, or EC2_WINDOWS."
  }
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
