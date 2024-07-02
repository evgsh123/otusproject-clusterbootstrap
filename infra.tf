locals {
    externaldns_values = templatefile("${path.module}/templates/externaldns-values.tmpl",
      {
        config_folder_id = "${var.folder_id}",
        config_auth_json = templatefile("${path.module}/templates/sa-cr-pusher-key.tpl.json",
           {
               key_id                   = yandex_iam_service_account_key.sa-auth-key.id,
               service_account_id       = yandex_iam_service_account_key.sa-auth-key.service_account_id,
               created_at               = yandex_iam_service_account_key.sa-auth-key.created_at,
               key_algorithm            = yandex_iam_service_account_key.sa-auth-key.key_algorithm,
               public_key               = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.public_key),"\""),
               private_key              = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.private_key),"\"")
           })
    })
      }

locals {
    cert-manager-webhook-yandex_values = templatefile("${path.module}/templates/cert-manager-webhook-yandex-values.tmpl",
      {
        config_folder_id = "${var.folder_id}",
        config_email = "mrevgsh@gmail.com",
        config_server= "https://acme-staging-v02.api.letsencrypt.org/directory",
        config_auth_json = templatefile("${path.module}/templates/sa-cr-pusher-key.tpl.json",
           {
               key_id                   = yandex_iam_service_account_key.sa-auth-key.id,
               service_account_id       = yandex_iam_service_account_key.sa-auth-key.service_account_id,
               created_at               = yandex_iam_service_account_key.sa-auth-key.created_at,
               key_algorithm            = yandex_iam_service_account_key.sa-auth-key.key_algorithm,
               public_key               = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.public_key),"\""),
               private_key              = trim(jsonencode(yandex_iam_service_account_key.sa-auth-key.private_key),"\"")
           })
    })
      }


resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

}

resource "helm_release" "externaldns" {
  name       = "externaldns"

  repository = "oci://cr.yandex/yc-marketplace/yandex-cloud/externaldns/helm"
  chart      = "externaldns"
  
  values =  ["${local.externaldns_values}"]
}

resource "helm_release" "cert-manager-webhook-yandex" {
  name       = "cert-manager-webhook-yandex"

  repository = "oci://cr.yandex/yc-marketplace/yandex-cloud/cert-manager-webhook-yandex/"
  chart      = "cert-manager-webhook-yandex"

  values =  ["${local.cert-manager-webhook-yandex_values}"]
}
