terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    tls = {
      source = "hashicorp/tls"
    }
    ssh = {
      source = "loafoe/ssh"
    }
   local =  {
    source = "hashicorp/local"
  }
  }
backend "s3" {
   endpoints = {
      s3 = "storage.yandexcloud.net"
    }
    bucket = "tf-state-evgsh"
    key    = "tfstate"
    region = "ru-central1"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
    zone = "ru-central1-a"
}

