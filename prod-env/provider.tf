provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.product_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.product_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.product_cluster.token
  load_config_file       = false
}

data "aws_eks_cluster_auth" "product_cluster" {
  name = aws_eks_cluster.product_cluster.name
}