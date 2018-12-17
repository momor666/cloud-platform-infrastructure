variable "kube-context" {
  default = "test-1"
}

variable "cert-manager-ns" {
  default = "cert-manager"
}

resource "kubernetes_service_account" "cert-manager-tiller" {
  metadata {
    name      = "tiller"
    namespace = "${var.cert-manager-ns}"
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-tiller" {
  metadata {
    name = "tiller"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "${var.cert-manager-ns}"
    api_group = ""
  }
}

resource "null_resource" "cert-manager-tiller" {
  depends_on = [
    "kubernetes_service_account.cert-manager-tiller",
    "kubernetes_cluster_role_binding.cert-manager-tiller",
  ]

  provisioner "local-exec" {
    command = "helm --kube-context ${var.kube-context} --tiller-namespace ${var.cert-manager-ns} init --wait --service-account tiller"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl --context ${var.kube-context} -n ${var.cert-manager-ns} delete deployment.apps/tiller-deploy service/tiller-deploy"
  }
}

resource "helm_release" "cert-manager" {
  name      = "cert-manager"
  chart     = "stable/"
  namespace = "${var.cert-manager-ns}"
  version   = "v0.5.2"

  set {
    name  = "image.tag"
    value = "v0.5.2"
  }

  depends_on = ["null_resource.cert-manager-tiller"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
