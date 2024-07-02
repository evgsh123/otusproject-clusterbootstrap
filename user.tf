resource "tls_private_key" "user_privatekey" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "user_csr" {
  private_key_pem = tls_private_key.user_privatekey.private_key_pem

  subject {
    common_name = "admin"
  }
}

resource "kubernetes_certificate_signing_request_v1" "kubernetes_user_csr" {
  metadata {
    name = "admin"
  }
  spec {
    usages      = ["client auth"]
    signer_name = "kubernetes.io/kube-apiserver-client"

    request = tls_cert_request.user_csr.cert_request_pem
  }

  auto_approve = true
}


resource "kubernetes_secret" "kubernetes_user_tls" {
  metadata {
    name = "admin-tls-secret"
    namespace = "default"
  }
  data = {
    "tls.crt" = kubernetes_certificate_signing_request_v1.kubernetes_user_csr.certificate
    "tls.key" = tls_private_key.user_privatekey.private_key_pem
  }
  type = "kubernetes.io/tls"
}

resource "kubernetes_role_binding_v1" "kubernetes_user_rolebinding" {
  metadata {
    name      = "admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

output "client-certificate-data" {
  sensitive = true
  value = base64encode(kubernetes_certificate_signing_request_v1.kubernetes_user_csr.certificate)
}

output "client-key-data" {
  sensitive = true
  value = base64encode(tls_private_key.user_privatekey.private_key_pem)
}
