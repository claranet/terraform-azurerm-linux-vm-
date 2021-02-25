# Azure Linux Virtual Machine

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-yellow.svg)](NOTICE) [![Apache V2 License](https://img.shields.io/badge/license-Apache%20V2-orange.svg)](LICENSE) [![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/claranet/linux-vm/azurerm/)

This module creates a [Linux Virtual Machine](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/).

Following tags are automatically set with default values: `env`, `stack`, `os_family`, `os_distribution`, `os_version`.

<!-- BEGIN_TF_DOCS -->
## Global versioning rule for Claranet Azure modules

| Module version | Terraform version | AzureRM version |
| -------------- | ----------------- | --------------- |
| >= 5.x.x       | 0.15.x & 1.0.x    | >= 2.0          |
| >= 4.x.x       | 0.13.x            | >= 2.0          |
| >= 3.x.x       | 0.12.x            | >= 2.0          |
| >= 2.x.x       | 0.12.x            | < 2.0           |
| <  2.x.x       | 0.11.x            | < 2.0           |

## Usage

This module is optimized to work with the [Claranet terraform-wrapper](https://github.com/claranet/terraform-wrapper) tool
which set some terraform variables in the environment needed by this module.
More details about variables set by the `terraform-wrapper` available in the [documentation](https://github.com/claranet/terraform-wrapper#environment).

```hcl
module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "x.x.x"

  azure_region = var.azure_region
}

module "rg" {
  source  = "claranet/rg/azurerm"
  version = "x.x.x"

  location    = module.azure_region.location
  client_name = var.client_name
  environment = var.environment
  stack       = var.stack
}

module "azure_network_vnet" {
  source  = "claranet/vnet/azurerm"
  version = "x.x.x"

  environment    = var.environment
  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  client_name    = var.client_name
  stack          = var.stack

  resource_group_name = module.rg.resource_group_name
  vnet_cidr           = ["10.10.0.0/16"]
}

module "azure_network_subnet" {
  source  = "claranet/subnet/azurerm"
  version = "x.x.x"

  environment    = var.environment
  location_short = module.azure_region.location_short
  client_name    = var.client_name
  stack          = var.stack

  resource_group_name  = module.rg.resource_group_name
  virtual_network_name = module.azure_network_vnet.virtual_network_name
  subnet_cidr_list     = ["10.10.10.0/24"]

  route_table_name = module.azure_network_route_table.route_table_name

  network_security_group_name = module.network_security_group.network_security_group_name
}

module "network_security_group" {
  source  = "claranet/nsg/azurerm"
  version = "x.x.x"

  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  resource_group_name = module.rg.resource_group_name
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
}

module "azure_network_route_table" {
  source  = "claranet/route-table/azurerm"
  version = "x.x.x"

  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  resource_group_name = module.rg.resource_group_name
}

resource "azurerm_availability_set" "vm_avset" {
  name                = "${var.stack}-${var.client_name}-${module.azure_region.location_short}-${var.environment}-as"
  location            = module.azure_region.location
  resource_group_name = module.rg.resource_group_name
  managed             = true
}

module "run_common" {
  source  = "claranet/run-common/azurerm"
  version = "x.x.x"

  client_name         = var.client_name
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  environment         = var.environment
  stack               = var.stack
  resource_group_name = module.rg.resource_group_name

  tenant_id                        = var.azure_tenant_id
  monitoring_function_splunk_token = null
}

module "vm" {
  source  = "claranet/linux-vm/azurerm"
  version = "x.x.x"

  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  resource_group_name = module.rg.resource_group_name

  subnet_id                             = module.azure_network_subnet.subnet_id
  diagnostics_storage_account_name      = module.run_common.logs_storage_account_name
  diagnostics_storage_account_sas_token = lookup(module.run_common.logs_storage_account_sas_token, "sastoken")
  vm_size                               = "Standard_B2s"
  custom_name                           = "app-${var.stack}-${var.client_name}-${module.azure_region.location_short}-${var.environment}-vm"
  admin_username                        = var.vm_administrator_login
  ssh_public_key                        = var.ssh_public_key

  availability_set_id = azurerm_availability_set.vm_avset.id
  # or use Availability Zone
  # zone_id = 1

  vm_image = {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  storage_data_disk_config = {
    appli_data_disk = {
      name                 = "appli_data_disk"
      disk_size_gb         = 512
      lun                  = 0
      storage_account_type = "Standard_LRS"
      extra_tags = {
        some_data_disk_tag = "some_data_disk_tag_value"
      }
    }
    logs_disk = {
      # Used to define Logical Unit Number (LUN) parameter
      lun          = 10
      disk_size_gb = 64
      caching      = "ReadWrite"
      extra_tags = {
        some_data_disk_tag = "some_data_disk_tag_value"
      }
    }
  }
}

```

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.0 |
| null | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_application_gateway_backend_address_pool_association.appgw_pool_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_gateway_backend_address_pool_association) | resource |
| [azurerm_network_interface_backend_address_pool_association.lb_pool_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_network_interface_security_group_association.nic_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.azure_monitor_agent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.log_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [null_resource.azure_monitor_link](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_password | Password for the administrator account of the virtual machine. | `string` | `null` | no |
| admin\_username | Username for Virtual Machine administrator account | `string` | n/a | yes |
| application\_gateway\_backend\_pool\_id | Id of the Application Gateway Backend Pool to attach the VM. | `string` | `null` | no |
| attach\_application\_gateway | True to attach this VM to an Application Gateway | `bool` | `false` | no |
| attach\_load\_balancer | True to attach this VM to a Load Balancer | `bool` | `false` | no |
| availability\_set\_id | Id of the availability set in which host the Virtual Machine. | `string` | `null` | no |
| azure\_monitor\_data\_collection\_rule\_id | Data Collection Rule ID from Azure Monitor for metrics and logs collection | `string` | n/a | yes |
| client\_name | Client name/account used in naming | `string` | n/a | yes |
| custom\_data | Custom data. See https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html#os_profile block | `any` | `null` | no |
| custom\_dns\_label | The DNS label to use for public access. VM name if not set. DNS will be <label>.westeurope.cloudapp.azure.com | `string` | `""` | no |
| custom\_ipconfig\_name | Custom name for the IP config of the NIC. Should be suffixed by "-nic-ipconfig". Generated if not set. | `string` | `null` | no |
| custom\_name | Custom name for the Virtual Machine. Should be suffixed by "-vm". Generated if not set. | `string` | `""` | no |
| custom\_nic\_name | Custom name for the NIC interface. Should be suffixed by "-nic". Generated if not set. | `string` | `null` | no |
| custom\_public\_ip\_name | Custom name for public IP. Should be suffixed by "-pubip". Generated if not set. | `string` | `null` | no |
| diagnostics\_storage\_account\_name | Name of the Storage Account in which store vm diagnostics | `string` | n/a | yes |
| diagnostics\_storage\_account\_sas\_token | SAS token of the Storage Account in which store vm diagnostics | `string` | n/a | yes |
| environment | Project environment | `string` | n/a | yes |
| extra\_tags | Extra tags to set on each created resource. | `map(string)` | `{}` | no |
| load\_balancer\_backend\_pool\_id | Id of the Load Balancer Backend Pool to attach the VM. | `string` | `null` | no |
| location | Azure location. | `string` | n/a | yes |
| location\_short | Short string for Azure location. | `string` | n/a | yes |
| log\_analytics\_workspace\_guid | GUID of the Log Analytics Workspace to link with | `string` | n/a | yes |
| log\_analytics\_workspace\_key | Access key of the Log Analytics Workspace to link with | `string` | n/a | yes |
| name\_prefix | Optional prefix for the generated name | `string` | `""` | no |
| nic\_enable\_accelerated\_networking | Should Accelerated Networking be enabled? Defaults to `false`. | `bool` | `false` | no |
| nic\_extra\_tags | Extra tags to set on the network interface. | `map(string)` | `{}` | no |
| nic\_nsg\_id | NSG ID to associate on the Network Interface. No association if null. | `string` | `null` | no |
| os\_disk\_caching | Specifies the caching requirements for the OS Disk | `string` | `"ReadWrite"` | no |
| os\_disk\_custom\_name | Custom name for OS disk. Should be suffixed by "-osdisk". Generated if not set. | `string` | `null` | no |
| os\_disk\_size\_gb | Specifies the size of the OS disk in gigabytes | `string` | `null` | no |
| os\_disk\_storage\_account\_type | The Type of Storage Account which should back this the Internal OS Disk. (Standard\_LRS, StandardSSD\_LRS and Premium\_LRS) | `string` | `"Standard_LRS"` | no |
| public\_ip\_extra\_tags | Extra tags to set on the public IP resource. | `map(string)` | `{}` | no |
| public\_ip\_sku | Sku for the public IP attached to the VM. Can be `null` if no public IP needed. | `string` | `"Standard"` | no |
| resource\_group\_name | Resource group name | `string` | n/a | yes |
| ssh\_public\_key | SSH public key | `string` | `null` | no |
| stack | Project stack name | `string` | n/a | yes |
| static\_private\_ip | Static private IP. Private IP is dynamic if not set. | `string` | `null` | no |
| storage\_data\_disk\_config | Map of objects to configure storage data disk(s).<br>    disk1 = {<br>      name                 = string ,<br>      create\_option        = string ,<br>      disk\_size\_gb         = string ,<br>      lun                  = string ,<br>      storage\_account\_type = string ,<br>      extra\_tags           = map(string)<br>    } | `any` | `{}` | no |
| storage\_data\_disk\_extra\_tags | [DEPRECATED] Extra tags to set on each data storage disk. | `map(string)` | `{}` | no |
| subnet\_id | Id of the Subnet in which create the Virtual Machine | `string` | n/a | yes |
| vm\_image | Virtual Machine source image information. See https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html#storage_image_reference. This variable cannot be used if `vm_image_id` is already defined. | `map(string)` | <pre>{<br>  "offer": "debian-10",<br>  "publisher": "Debian",<br>  "sku": "10",<br>  "version": "latest"<br>}</pre> | no |
| vm\_image\_id | The ID of the Image which this Virtual Machine should be created from. This variable cannot be used if `vm_image` is already defined. | `string` | `null` | no |
| vm\_plan | Virtual Machine plan image information. See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#plan. This variable has to be used for BYOS image. Before using BYOS image, you need to accept legal plan terms. See https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az_vm_image_accept_terms. | <pre>object({<br>    name      = string<br>    product   = string<br>    publisher = string<br>  })</pre> | `null` | no |
| vm\_size | Size (SKU) of the Virtual Machine to create. | `string` | n/a | yes |
| zone\_id | Index of the Availability Zone which the Virtual Machine should be allocated in. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| vm\_id | ID of the Virtual Machine |
| vm\_identity | System Identity assigned to the Virtual Machine |
| vm\_name | Name of the Virtual Machine |
| vm\_nic\_id | ID of the Network Interface Configuration attached to the Virtual Machine |
| vm\_nic\_ip\_configuration\_name | Name of the IP Configuration for the Network Interface Configuration attached to the Virtual Machine |
| vm\_nic\_name | Name of the Network Interface Configuration attached to the Virtual Machine |
| vm\_private\_ip\_address | Private IP address of the Virtual Machine |
| vm\_public\_domain\_name\_label | Public DNS of the Virtual machine |
| vm\_public\_ip\_address | Public IP address of the Virtual Machine |
| vm\_public\_ip\_id | Public IP ID of the Virtual Machine |
<!-- END_TF_DOCS -->
## Related documentation

Microsoft Azure documentation: [docs.microsoft.com/en-us/azure/virtual-machines/linux/](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/)
