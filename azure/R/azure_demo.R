




library(AzureRMR)
library(AzureStor)
library(AzureAuth)
library(tidyverse)
#-------------------------------------------------------------------------------
az <- create_azure_login()
# az <- az_rm$new(tenant = "93f33571-550f-43cf-b09f-cd331338d086",
#                 app = "1a9f5ae8-c492-44e6-a785-34d4bd58a2ad",
#                 password = "f15c9a8a-2c2d-4c5a-b11d-4e62c8934eca")
sub <- az$get_subscription("5e5ae61b-5894-4a95-a88c-74d18cb7d9f6")
# sub$create_resource_group(name = "azure_demo_rg", location = "southcentralus")
rg <- sub$get_resource_group(name = "ai-guild-rg")
# stor <- rg$get_resource(type = "Microsoft.Storage/storageAccounts",
#                         name = "cs25e5ae61b5894x4a95xa88")
st <- rg$get_resource(
    type = "Microsoft.Storage/storageAccounts",
    name = "aiguildstorageacct")

st <- az$get_subscription("5e5ae61b-5894-4a95-a88c-74d18cb7d9f6")$
    get_resource_group(name = "ai-guild-rg")$
    get_resource(
        type = "Microsoft.Storage/storageAccounts",
        name = "aiguildstorageacct")
    

token <- get_azure_token("https://storage.azure.com",
    tenant = "93f33571-550f-43cf-b09f-cd331338d086",
    app = "1a9f5ae8-c492-44e6-a785-34d4bd58a2ad", 
    password = "f15c9a8a-2c2d-4c5a-b11d-4e62c8934eca")

cont <- storage_endpoint(
    "https://aiguildstorageacct.dfs.core.windows.net",
    token = token, 
    key = "AXFWoO/dsp5/vf58IBRRi8xY3YX/e5bBLcmAS+5tINPdUoyeZxd8lavLvQISmgOwtDHk1cSa7MAQgjVM59TCYA==") %>% 
    storage_container("cfs")
list_storage_files(cont)$name
