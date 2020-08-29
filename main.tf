
#AKS using terraform, spot node pool - based on https://github.com/terraform-providers/terraform-provider-azurerm
#tweaked by Mahesh, Aug 29 

provider "azurerm" {
  features {

  }
  version         = "=2.20.0"
  subscription_id = "xxxx"
  tenant_id       = "xxxxx"
}
resource "azurerm_resource_group" "mikkyakstfrg" {
  name     = "${var.prefix}-rg"
  location = var.location

}

resource "azurerm_kubernetes_cluster" "mikkyaks" {
  name                = "${var.prefix}-k8s"
  location            = azurerm_resource_group.mikkyakstfrg.location
  resource_group_name = azurerm_resource_group.mikkyakstfrg.name
  dns_prefix          = "${var.prefix}-k8s-dns"
  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
  }
  addon_profile {
    aci_connector_linux {
      enabled = false
    }
    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled = false
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "mikkynodepool" {
  name                  = "mikkyspot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.mikkyaks.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 3
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = 0.5 # note: this is the "maximum" price
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]


}
