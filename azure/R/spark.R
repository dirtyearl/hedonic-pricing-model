




# library(RevoScaleR)
# library(sparklyr)
# RxSpark()
# cc <- rxSparkConnect(reset = TRUE, interop = "sparklyr")
# sc <- rxGetSparklyrConnection(cc)
# 
# "edavis67@ai-guild-cluster001472.azurehdinsight.net"

library(sparklyr)
sc <- spark_connect(config = spark_config_kubernetes(
  "k8s://https://aispark001472.southcentralus.azurecontainer.io:80",
  account = "default",
  image = "aispark.azurecr.io/spark:latest",
  version = "2.3.1"))

