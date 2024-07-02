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
  kubernetes = {
    source = "hashicorp/kubernetes"
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


provider "kubernetes" {
     host                   = data.yandex_kubernetes_cluster.otus-cluster.master.0.external_v4_endpoint
     cluster_ca_certificate = data.yandex_kubernetes_cluster.otus-cluster.master.0.cluster_ca_certificate
     token                  = data.yandex_client_config.client.iam_token
}


provider "helm" {
   kubernetes {
     host                   = data.yandex_kubernetes_cluster.otus-cluster.master.0.external_v4_endpoint
     cluster_ca_certificate = data.yandex_kubernetes_cluster.otus-cluster.master.0.cluster_ca_certificate
     token                  = data.yandex_client_config.client.iam_token
   }
}
