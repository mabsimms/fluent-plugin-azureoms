#!/bin/bash

kv_name_workspace="OMS-WORKSPACE"
kv_name_key="OMS-KEY"

# Check to see if OMS_WORKSPACE and OMS_KEY are set
if [ -z ${OMS_WORKSPACE+x} ]; then
	echo "OMS_WORKSPACE and OMS_KEY not set; checking KeyVault"
	
	if [ -z ${OMS_KEYVAULT+x} ]; then
		echo "OMS_KEYVAULT not set; please set variable with a valid keyvault instance"
		exit 0 
    fi

	# Get the OMS_WORKSPACE and OMS_KEYVAULT settings from keyvault
	oms_val_workspace=$(az keyvault secret show  --vault-name ${OMS_KEYVAULT} \
		--name $kv_name_workspace | jq .value | tr -d '"')
	oms_val_key=$(az keyvault secret show  --vault-name ${OMS_KEYVAULT} \
		--name $kv_name_key | jq .value | tr -d '"')

	echo "OMS Workspace retrieved; $oms_val_workspace"
	export OMS_WORKSPACE=$oms_val_workspace

	echo "OMS Key retrieved; $oms_val_key"
	export OMS_KEY=$oms_val_key
else
	echo "OMS workspace is set to |$OMS_WORKSPACE|"
fi



