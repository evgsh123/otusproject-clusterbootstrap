data "yandex_client_config" "client" {}

data "yandex_kubernetes_cluster" "otus-cluster" {
  name = "${yandex_kubernetes_cluster.otus-cluster.name}"
}


resource "kubernetes_service_account" "k8s-sa" {
  metadata {
    name = "adm"
  }
}

resource "kubernetes_secret" "k8s-secret" {
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.k8s-sa.metadata.0.name
    }
    generate_name = "otus-adm"
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
