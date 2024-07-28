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

locals {
   prometheus_values = templatefile("${path.module}/templates/kube-prometheus-values.yaml.tmpl",
      {
        TG_BOT_TOKEN = "${var.TG_BOT_TOKEN}"
     })
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  values =  [file("${path.module}/templates/nginx-ingress-values.yaml")]

  depends_on = [ helm_release.kube-prometheus ]
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

resource "helm_release" "loki" {
  name       = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace =  "infra"
  create_namespace = true


  values =  [templatefile("${path.module}/templates/loki-values.yaml.tmpl",{
            SECRET_KEY  = yandex_iam_service_account_static_access_key.s3.secret_key,
            ACCESS_KEY =  yandex_iam_service_account_static_access_key.s3.access_key})]
}

resource "helm_release" "promtail" {
  name       = "promtail"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace =  "infra"
  create_namespace = true


  values =  [file("${path.module}/templates/promtail-values.yaml")]
}

resource "helm_release" "grafana" {
  name       = "grafana"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace =  "infra"
  create_namespace = true


  values =  [file("${path.module}/templates/grafana-values.yaml")]
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus"

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kube-prometheus"
  namespace =  "infra"
  create_namespace = true

  values =  ["${local.prometheus_values}"]

}
resource "helm_release" "jaeger" {
  name       = "jaeger"

  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace =  "infra"
  create_namespace = true


  depends_on = [ helm_release.kube-prometheus ]
  values =  [file("${path.module}/templates/jaeger.yaml")]
}

resource "kubectl_manifest" "prometheusrule_alert" {
    yaml_body = file("${path.module}/templates/prometheusrule.alert.yaml")
    depends_on = [ helm_release.kube-prometheus ]
}
