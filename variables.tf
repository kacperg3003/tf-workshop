variable "aws_ec2_type" {
  type        = string
  description = "The size of the AWS EC2 instance"
  default     = "c7i.8xlarge"
}

variable "azure_vm_size" {
  type        = string
  description = "The size of the Azure Vitual Machine"
  default     = "Standard_E32s_v3"
}