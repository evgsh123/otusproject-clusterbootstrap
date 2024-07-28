
resource "yandex_vpc_network" "otus-net" {}


resource "yandex_vpc_subnet" "otus-subnet" {
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.otus-net.id}"
  v4_cidr_blocks = ["10.5.0.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  folder_id      = "${var.folder_id}"
  name = "my-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  folder_id      = "${var.folder_id}"
  name       = "my-route-table"
  network_id = yandex_vpc_network.otus-net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_iam_service_account" "otus-sa" {
  name        = "otus-sa"
}

resource "yandex_kubernetes_cluster" "otus-cluster" {
  name = "otus"
 network_id = yandex_vpc_network.otus-net.id
  master {
  public_ip = true 
   master_location {
     zone      = yandex_vpc_subnet.otus-subnet.zone
     subnet_id = yandex_vpc_subnet.otus-subnet.id
   }
 }
 service_account_id      = yandex_iam_service_account.otus-sa.id
 node_service_account_id = yandex_iam_service_account.otus-sa.id
   depends_on = [
     yandex_resourcemanager_folder_iam_member.editor,
     yandex_resourcemanager_folder_iam_member.images-puller
   ]
}


resource "yandex_iam_service_account_key" "sa-auth-key" {
  service_account_id = yandex_iam_service_account.otus-sa.id
  key_algorithm      = "RSA_4096"
}



resource "yandex_resourcemanager_folder_iam_member" "editor" {
 role      = "editor"
 folder_id = "${var.folder_id}"
 member    = "serviceAccount:${yandex_iam_service_account.otus-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "dnseditor" {
 role      = "dns.editor"
 folder_id = "${var.folder_id}"
 member    = "serviceAccount:${yandex_iam_service_account.otus-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storageeditor" {
 role      = "storage.admin"
 folder_id = "${var.folder_id}"
 member    = "serviceAccount:${yandex_iam_service_account.otus-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
 folder_id = "${var.folder_id}"
 role      = "container-registry.images.puller"
 member    = "serviceAccount:${yandex_iam_service_account.otus-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-pusher" {
 folder_id = "${var.folder_id}"
 role      = "container-registry.images.pusher"
 member    = "serviceAccount:${yandex_iam_service_account.otus-sa.id}"
}

resource "yandex_kubernetes_node_group" "infra" {
  cluster_id  = "${yandex_kubernetes_cluster.otus-cluster.id}"
  name        = "infra"
  description = "infra node group"
  version     = "1.27"

  node_labels = {
    "node-role" = "infra"
  }
 #node_taints = ["node-role=infra:NoSchedule"]

  instance_template {
    platform_id = "standard-v2"

   
  resources {
    core_fraction = 20 
    cores  = 4
    memory = 8 
  }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

  network_interface {
    subnet_ids         = ["${yandex_vpc_subnet.otus-subnet.id}"]
     }

   metadata = {
     ssh-keys = "ubuntu:${trimspace(tls_private_key.ssh-key.public_key_openssh)}"
     #user-data = file("${path.module}/userdata.yaml")
    }
    
   scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}

resource "yandex_kubernetes_node_group" "workload" {
  cluster_id  = "${yandex_kubernetes_cluster.otus-cluster.id}"
  name        = "workload"
  description = "Workload node group"
  version     = "1.27"

  node_labels = {
    "node-role" = "workload"
  }
 #node_taints = ["node-role=infra:NoSchedule"]

  instance_template {
    platform_id = "standard-v2"

   
  resources {
    core_fraction = 20 
    cores  = 4
    memory = 8 
  }
    boot_disk {
      type = "network-hdd"
      size = 30
    }

  network_interface {
    subnet_ids         = ["${yandex_vpc_subnet.otus-subnet.id}"]
     }

   metadata = {
     ssh-keys = "ubuntu:${trimspace(tls_private_key.ssh-key.public_key_openssh)}"
    }
    
   scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}


resource "local_sensitive_file" "auth_key_file" {
           filename = "${path.module}/out/auth.key.json"
           content  = templatefile("${path.module}/templates/sa-cr-pusher-key.tpl.json",
           {
               key_id                   = yandex_iam_service_account_key.sa-auth-key.id,
               service_account_id       = yandex_iam_service_account_key.sa-auth-key.service_account_id,
               created_at               = yandex_iam_service_account_key.sa-auth-key.created_at,
               key_algorithm            = yandex_iam_service_account_key.sa-auth-key.key_algorithm,
               public_key               = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.public_key),"\""),
               private_key              = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.private_key),"\"")
           })
}
