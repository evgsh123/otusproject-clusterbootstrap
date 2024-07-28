
resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = "1500"
  create_namespace = true
  namespace  = "argocd"
  values = [file("${path.module}/templates/argocd.yaml")]
}

resource "kubectl_manifest" "proj_stage" {
    yaml_body = file("${path.module}/templates/apps-stage-project.yaml")
    depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "apps_stage" {
    yaml_body = file("${path.module}/templates/apps-stage-application.yaml")
    depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "proj_prod" {
    yaml_body = file("${path.module}/templates/apps-prod-project.yaml")
    depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "apps_prod" {
    yaml_body = file("${path.module}/templates/apps-prod-application.yaml")
    depends_on = [ helm_release.argocd ]
}
