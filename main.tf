resource "aws_key_pair" "kube-kez" {
    key_name = "${var.name}-kez"
    public_key = var.pub-key
  
}
resource "aws_vpc" "net-main" {
    cidr_block = var.vpc-cidr
    enable_dns_hostnames = true

    tags = {
      Name = "${var.name}-vpc"
    }
  
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.net-main.id
    cidr_block = "10.23.128.0/24"
    availability_zone = lookup(var.availability-zone, "az1")

    tags = {
      Name = "${var.name}-pb"
    }
       
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.net-main.id
    cidr_block = "10.23.64.0/18"
    availability_zone = lookup(var.availability-zone, "az2")

    tags = {
      Name = "${var.name}-pr"
    }
       
}

resource "aws_eip" "nat" {
  domain   = "vpc"

}

resource "aws_nat_gateway" "natgw" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id
  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.net-main.id
  
}

resource "aws_route_table" "rt-public" {
    vpc_id = aws_vpc.net-main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
  
}

resource "aws_route_table" "rt-private" {
    vpc_id = aws_vpc.net-main.id
    

    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.natgw.id
    }
  
}

resource "aws_route_table_association" "pub-rtassoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_route_table_association" "pri-rtassoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rt-private.id
}

resource "aws_security_group" "kubeadm_sg" {
  name        = "kubeadm-security-group"
  description = "Security group for Kubernetes nodes"
  vpc_id = aws_vpc.net-main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "kube-nic" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["10.23.128.100"]
  security_groups = [aws_security_group.kubeadm_sg.id]
}


resource "aws_instance" "kubeadm_master" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = var.instance-type
  key_name = aws_key_pair.kube-kez.key_name 
  subnet_id = aws_subnet.public.id
  availability_zone = lookup(var.availability-zone, "az1")
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.kubeadm_sg.id]

#   network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.kube-nic.id
#   }

  tags = {
    Name = "${lookup(var.instance-name, "name1")}-server"
  }

  user_data = <<-EOF
          #!/bin/bash
          sudo apt-get update
          sudo apt-get install -y docker.io
          sudo systemctl enable docker
          sudo systemctl start docker
          sudo curl -fsSL https://get.docker.com -o get-docker.sh
          sudo sh get-docker.sh
          sudo usermod -aG docker $USER
          sudo systemctl restart docker
          sudo swapoff -a
          sudo sed -i '/swap/d' /etc/fstab
          sudo apt-get install -y apt-transport-https curl
          sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
          sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
          sudo apt-get update
          sudo apt-get install -y kubelet kubeadm kubectl
          sudo kubeadm init --pod-network-cidr=10.244.0.0/16
          mkdir -p $HOME/.kube
          sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
          sudo chown $(id -u):$(id -g) $HOME/.kube/config
          EOF
}

resource "aws_instance" "kubeadm_worker1" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = var.instance-type
  subnet_id = aws_subnet.public.id
  key_name = aws_key_pair.kube-kez.key_name 
  availability_zone = lookup(var.availability-zone, "az1")
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.kubeadm_sg.id]


#    network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.kube-nic.id
#   }

  tags = {
    Name = "${lookup(var.instance-name, "name2")}-server"
  }

  user_data = <<-EOF
          #!/bin/bash
          sudo apt-get update
          sudo apt-get install -y docker.io
          sudo systemctl enable docker
          sudo systemctl start docker
          sudo curl -fsSL https://get.docker.com -o get-docker.sh
          sudo sh get-docker.sh
          sudo usermod -aG docker $USER
          sudo systemctl restart docker
          sudo swapoff -a
          sudo sed -i '/swap/d' /etc/fstab
          sudo apt-get install -y apt-transport-https curl
          sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
          sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
          sudo apt-get update
          sudo apt-get install -y kubelet kubeadm kubectl
          EOF
}


resource "aws_instance" "kubeadm_worker2" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = var.instance-type
  subnet_id = aws_subnet.public.id
  key_name = aws_key_pair.kube-kez.key_name
  availability_zone = lookup(var.availability-zone, "az1")
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.kubeadm_sg.id]



#    network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.kube-nic.id
#   }

  tags = {
    Name = "${lookup(var.instance-name, "name3")}-server"
  }

  user_data = <<-EOF
          #!/bin/bash
          sudo apt-get update
          sudo apt-get install -y docker.io
          sudo systemctl enable docker
          sudo systemctl start docker
          sudo curl -fsSL https://get.docker.com -o get-docker.sh
          sudo sh get-docker.sh
          sudo usermod -aG docker $USER
          sudo systemctl restart docker
          sudo swapoff -a
          sudo sed -i '/swap/d' /etc/fstab
          sudo apt-get install -y apt-transport-https curl
          sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
          sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
          sudo apt-get update
          sudo apt-get install -y kubelet kubeadm kubectl
          EOF
}
