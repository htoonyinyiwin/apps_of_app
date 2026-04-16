resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  # Minimal install — override nothing, use chart defaults
  # We'll layer on customizations (ingress, SSO, HA) in later phases
}
