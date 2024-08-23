
variable "project" {
  description = "The project in which to hold the components"
  type        = string
}

variable "region" {
  description = "The region where the components should be created"
  type        = string
}

variable "zone" {
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  type        = string
}

/*
Optional Variables

Defaults will be used for these, if not overridden at runtime.
*/

variable "bastion_machine_type" {
  description = "The instance size to use for your bastion instance."
  type        = string
  default     = "g1-small"
}

variable "bastion_hostname" {
  type    = string
  default = "gke-demo-bastion"
}

variable "bastion_tags" {
  description = "A list of tags applied to your bastion instance."
  type        = list(string)
  default     = ["bastion"]
}

variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "gke-demo-cluster"
}

variable "initial_node_count" {
  description = "The number of nodes initially provisioned in the cluster"
  type        = string
  default     = "3"
}

variable "ip_range" {
  description = "The CIDR from which to allocate cluster node IPs"
  type        = string
  default     = "10.0.96.0/22"
}

variable "master_cidr_block" {
  description = "The CIDR from which to allocate master IPs"
  type        = string
  default     = "10.0.90.0/28"
}

variable "node_machine_type" {
  description = "The instance to use for your node instances"
  type        = string
  default     = "n1-standard-1"
}

variable "node_tags" {
  description = "A list of tags applied to your node instances."
  type        = list(string)
  default     = ["poc"]
}

variable "secondary_ip_range" {
  // See https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  description = "The CIDR from which to allocate pod IPs for IP Aliasing."
  type        = string
  default     = "10.0.92.0/22"
}

variable "secondary_subnet_name" {
  // See https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  description = "The name to give the secondary subnet."
  type        = string
  default     = "kube-net-secondary-sub"
}

variable "subnet_name" {
  description = "The name to give the primary subnet"
  type        = string
  default     = "kube-net-subnet"
}

variable "vpc_name" {
  description = "The name to give the virtual network"
  type        = string
  default     = "kube-net"
}

variable "ssh_user_bastion" {
  description = "ssh user for bastion server"
  type        = string
  default     = "jenkins"
}