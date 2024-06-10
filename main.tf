terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "" # OAuth-токен яндекса
  cloud_id  = "b1gij1dp8gfciqs3cuhk"
  folder_id = "b1gsls3tk9b6uk0d01g9"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "default" { 
  name = "test-instance"
	platform_id = "standard-v1"

  resources {
    core_fraction = 5 
    cores  = 2 
    memory = 1 
  }

  boot_disk {
    initialize_params {
      image_id = "fd88m3uah9t47loeseir" 
    }
  }

  network_interface {
    subnet_id = "e9bdgo95ucmut6r7pioq" 
    nat = true 
  }
}
