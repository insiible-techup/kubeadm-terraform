variable "pub-key" {
    description = "key to use"
    type = string
    default = ""
  
}

variable "name" {
    description = "name to use"
    type = string
    default = "kubeadm"
  
}

variable "region" {
    description = "region to use"
    type = string
    default = "us-east-1"
  
}

variable "instance-type" {
    description = "instance type to use"
    type = string
    default = "t3.medium"
  
}

variable "instance-name" {
    description = "name to call instance"
    type = map(string)
    default = {
      "name1" = "kubeadm-master"
      "name2" = "kubeadm-worker1"
      "name3" = "kubeadm-worker2"
    }
  
}

variable "availability-zone" {
    description = "az to use"
    type = map(string)
    default = {
      "az1" = "us-east-1a"
      "az2" = "us-east-1b"
      "az3" = "us-east-1c"
    }
  
}
variable "vpc-cidr" {
    description = "cidr to use"
    type = string
    default = "10.23.0.0/16"
  
}