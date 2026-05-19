variable "aws_ec2_type" {
  type        = string
  description = "The size of the AWS EC2 instance"
  default     = "t3.medium" # Maybe t3.medium?
}

variable "azure_vm_size" {
  type        = string
  description = "The size of the Azure Vitual Machine"
  default     = "Standard_B2s" # Maybe Standard_B2s?
}