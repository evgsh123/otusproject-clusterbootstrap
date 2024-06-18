
resource "yandex_vpc_network" "otus-net" {}


resource "yandex_vpc_subnet" "otus-subnet" {
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.otus-net.id}"
  v4_cidr_blocks = ["10.5.0.0/24"]
}


resource "yandex_compute_instance" "cp" { 
  count = 3
  name = "cp${count.index}"
  hostname = "cp${count.index}"
 
  platform_id = "standard-v1"

  resources {
    core_fraction = 20 
    cores  = 2
    memory = 4 
  }

  boot_disk {
    initialize_params {
      type = "network-ssd"
      image_id = "fd88m3uah9t47loeseir"
      size = 30 
     }
  } 

  network_interface {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}" 
    nat = true 
     }

   metadata = {
     ssh-keys = "ubuntu:${trimspace(tls_private_key.ssh-key.public_key_openssh)}"
     user-data = file("${path.module}/userdata.yaml")
    }
  }

resource "yandex_lb_target_group" "cplbgrp" {
  name      = "cplbggrp"

  target {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}"
    address   = "${yandex_compute_instance.cp.0.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}"
    address   = "${yandex_compute_instance.cp.1.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}"
    address   = "${yandex_compute_instance.cp.2.network_interface.0.ip_address}"
  }
}

resource "yandex_lb_network_load_balancer" "cplb" {
  name = "cplb"
  listener {
    name = "https"
    port = 443
    target_port = 6443
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = "${yandex_lb_target_group.cplbgrp.id}"
    healthcheck {
      name = "tcp-check"
      tcp_options {
        port = 6443
      }
    }
  }
}

resource "ssh_resource" "cp0" {
  host         = "${yandex_compute_instance.cp.0.network_interface.0.nat_ip_address}"
  #bastion_host = "jumpgate.remote-host.com"
  user         = "ubuntu"
  private_key = "${trimspace(tls_private_key.ssh-key.private_key_openssh)}"
  when         = "create" # Default
  timeout = "10m"
  commands = [
    "sudo cloud-init status --wait > /tmp/bootstrap-first-node.log 2>&1",
    "sudo /usr/local/bin/bootstrap-first-node.sh ${[for s in yandex_lb_network_load_balancer.cplb.listener: s.external_address_spec.*.address].0[0]} >> /tmp/bootstrap-first-node.log 2>&1",
    "cat /tmp/cp_join.sh /tmp/worker_join.sh"
  ]
}


resource "ssh_resource" "cp" {
  count = 2
  host         = yandex_compute_instance.cp.*.network_interface.0.nat_ip_address[count.index +1]
  #bastion_host = "jumpgate.remote-host.com"
  user         = "ubuntu"
  private_key = "${trimspace(tls_private_key.ssh-key.private_key_openssh)}"
  when         = "create" # Default
  timeout = "5m"
  commands = [
    "sudo cloud-init status --wait > /tmp/bootstrap-cp-node.log 2>&1",
    "sudo ${split("\n",ssh_resource.cp0.result).0} >> /tmp/bootstrap-cp-node.log 2>&1",
  ]
}

resource "ssh_resource" "cp0-kube-config" {
  host         = "${yandex_compute_instance.cp.0.network_interface.0.nat_ip_address}"
  #bastion_host = "jumpgate.remote-host.com"
  user         = "ubuntu"
  private_key = "${trimspace(tls_private_key.ssh-key.private_key_openssh)}"
  when         = "create" # Default
  timeout = "10m"
  commands = [
    "sudo cat /etc/kubernetes/admin.conf",
  ]
}

output "kube-config" {
  value = split("\n",ssh_resource.cp0-kube-config.result)
  sensitive   = true
}

output "cp0-nat-ip" {
  value = "${yandex_compute_instance.cp.0.network_interface.0.nat_ip_address}"
}
output "cp1-nat-ip" {
  value = "${yandex_compute_instance.cp.1.network_interface.0.nat_ip_address}"
}
output "cp2-nat-ip" {
  value = "${yandex_compute_instance.cp.2.network_interface.0.nat_ip_address}"
}
output "cp-lb-ip" {
  value = "${[for s in yandex_lb_network_load_balancer.cplb.listener: s.external_address_spec.*.address].0[0]}"
}


resource "local_file" "kube-config" {
    content  = ssh_resource.cp0-kube-config.result
    filename = "kube-config"
}
