#!/bin/bash

# Check environment settings
set_variables() { 
    export RESOURCE_GROUP=masfluenttest-rg
    export KEYVAULT_NAME=masdevbox-kv
    export LOCATION=eastus

    export K8_DNS_PREFIX=masfluenttest
    export K8_CLUSTER_NAME=masfluenttest
    export K8_ADMIN_USERNAME=masimms
    export K8_NODE_COUNT=3

    kv_ssh_key="k8ssh-key"
    kv_ssh_pub="k8ssh-key-pub"
    kv_ad_spid="k8ad-spid"
    kv_ad_secr="k8ad-client-secret"
}

deploy_shared() { 
    az group create --name $RESOURCE_GROUP --location $LOCATION

    # Create a key vault
    az keyvault create --resource-group ${RESOURCE_GROUP} \
        --location ${LOCATION} --sku standard \
        --name ${KEYVAULT_NAME}

    # Check for SSH credentials
     # Create and store the jumpbox keys
    if [ ! -f ~/.ssh/fluenttest ]; then
        echo "Creating or retrieving SSH keys"

	    ssh_key=$(az keyvault secret show  --vault-name ${KEYVAULT_NAME} --name $kv_ssh_key | jq .value | tr -d '"')
	    ssh_key_pub=$(az keyvault secret show  --vault-name ${KEYVAULT_NAME} --name $kv_ssh_pub | jq .value | tr -d '"')

        if [ -z "${ssh_key}" ]; then
            echo "No ssh key found in keyvault; generating"

            # TODO - check to see if the keys exist before regenerating
            ssh-keygen -f ~/.ssh/fluenttest -P ""

            az keyvault secret set --vault-name ${KEYVAULT_NAME} --name $kv_ssh_key --file  ~/.ssh/fluenttest
            az keyvault secret set --vault-name ${KEYVAULT_NAME} --name $kv_ssh_pub --file  ~/.ssh/fluenttest.pub
        else
            echo "SSH key data retrieved from KeyVault"            
            echo $ssh_key > ~/.ssh/fluenttest
            echo $ssh_key_pub > ~/.ssh/fluenttest.pub
        fi
    fi
    export SSH_KEYDATA=`cat ~/.ssh/fluenttest.pub`

    # Create a service principal and secret
    spid=$(az keyvault secret show  --vault-name ${KEYVAULT_NAME} --name $kv_ad_spid | jq .value | tr -d '"')
	sppw=$(az keyvault secret show  --vault-name ${KEYVAULT_NAME} --name $kv_ad_secr | jq .value | tr -d '"')

    if [ -z ${spid} ]; then
        echo "Active directory role not found in KeyVault; creating"
        export subid=$(az account show --query id | tr -d '"')
        az ad sp create-for-rbac --role="Contributor" \
            --scopes="/subscriptions/$subid" > adrole.json
        export spid=$(cat adrole.json | jq .appId | tr -d '"')
        export sppw=$(cat adrole.json | jq .password | tr -d '"')
        rm adrole.json

        az keyvault secret set --vault-name ${KEYVAULT_NAME} \
            --name $kv_ad_spid --value $spid
        az keyvault secret set --vault-name ${KEYVAULT_NAME} \
            --name $kv_ad_secr --value $sppw
    fi
}

deploy_cluster() { 

    az aks create --resource-group $RESOURCE_GROUP \
        --name $K8_CLUSTER_NAME \
        --ssh-key-value "$SSH_KEYDATA" \
        --dns-name-prefix $K8_DNS_PREFIX \
        --admin-username $K8_ADMIN_USERNAME \
        --node-count $K8_NODE_COUNT \
        --service-principal $spid \
        --client-secret $sppw

    az aks get-credentials --resource-group $RESOURCE_GROUP \
        --name $K8_CLUSTER_NAME

    kubectl get nodes
}

configure_kubectl() { 
    echo "TODO"
}

main() { 
    # Set up the cluster
    set_variables
    deploy_shared
    deploy_cluster
    configure_kubectl

    # Deploy the monitoring agents
    
}