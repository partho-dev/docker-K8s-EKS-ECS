resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.15.0"

# here the CRD is created to automatically renew the cert from letsencrypt
  set {
    name  = "installCRDs"
    value = "true"
  }

#   values = [file("${path.module}/17.1.cluster-issuer.yaml")]

  depends_on = [helm_release.external_nginx]
}

# Dont forget to apply the cluster-issuer.yaml file (17.1.cluster-issuer.yaml)
# kubectl apply -f 17.1.cluster-issuer.yaml
