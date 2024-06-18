resource "yandex_compute_instance" "infra" { 
  count = 3
  name = "infra${count.index}"
  hostname = "infra${count.index}"
 
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
      size = 10 
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
resource "ssh_resource" "infra" {
  count = 3
  host         = yandex_compute_instance.infra.*.network_interface.0.nat_ip_address[count.index]
  #bastion_host = "jumpgate.remote-host.com"
  user         = "ubuntu"
  private_key = "${trimspace(tls_private_key.ssh-key.private_key_openssh)}"
  when         = "create" # Default
  timeout = "10m"
  commands = [
    "sudo cloud-init status --wait > /tmp/bootstrap-infra-node.log 2>&1",
    "sudo ${split("\n",ssh_resource.cp0.result).1} >> /tmp/bootstrap-infra-node.log 2>&1",
  ]
}
