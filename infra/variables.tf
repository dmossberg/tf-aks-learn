variable "region" {
  type    = string
  default = "westeurope"
}

variable "tenant_id" {
  type    = string
  default = "72f988bf-86f1-41af-91ab-2d7cd011db47"
}

variable "aks_rg_name" {
  type    = string
  default = "aks-learn"
}

variable "aks_name" {
  type    = string
  default = "aks-public"
}

variable "aks_admin_group_object_ids" {
  type    = list(string)
  default = ["bcf60be2-0a6d-4dc1-912a-52d829bda22c"]
}

variable "aks_subnet_name" {
  type    = string
  default = "aks-subnet"
}

variable "acr_rg_name" {
  type    = string
  default = "rg-containers-shared"
}

variable "acr_name" {
  type    = string
  default = "dockerforall"
}


