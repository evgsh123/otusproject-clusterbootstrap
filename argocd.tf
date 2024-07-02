resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}


resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = "1500"
  namespace  = kubernetes_namespace.argocd.id
  values = [file("${path.module}/templates/argocd.yaml")]
}
