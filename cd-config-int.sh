#!/bin/bash

################################################################
#                                                              #
# Configuration for continuous deployment of krug services.    #
#                                                              #
################################################################

# Define hosts of gateway service instances, the value will be used when calling API of each instance to refresh service list on gateway
declare -A GATEWAY_HOSTS
GATEWAY_HOSTS['krug-gateway-1']='10.201.11.54'
GATEWAY_HOSTS['krug-gateway-2']='10.201.11.55'

# Define hosts of each service instance which is also the host for consul healthy check
# The key MUST be unique ID of each instance
declare -A SERVICE_HOSTS
SERVICE_HOSTS['account-service-1']='10.201.11.54' 
SERVICE_HOSTS['account-service-2']='10.201.11.55'

SERVICE_HOSTS['partner-service-1']='10.201.11.54'
SERVICE_HOSTS['partner-service-2']='10.201.11.55'

SERVICE_HOSTS['session-service-1']='10.201.11.54' 
SERVICE_HOSTS['session-service-2']='10.201.11.55'

SERVICE_HOSTS['report-service-1']='10.201.11.54'
SERVICE_HOSTS['report-service-2']='10.201.11.55'

SERVICE_HOSTS['jackpot-service-1']='10.201.11.54'
SERVICE_HOSTS['jackpot-service-2']='10.201.11.55'

SERVICE_HOSTS['bonus-service-1']='10.201.11.54'
SERVICE_HOSTS['bonus-service-2']='10.201.11.55'

SERVICE_HOSTS['genplus-service-1']='10.201.11.54'
SERVICE_HOSTS['genplus-service-2']='10.201.11.55'

SERVICE_HOSTS['history-service-1']='10.201.11.54'
SERVICE_HOSTS['history-service-2']='10.201.11.55'

SERVICE_HOSTS['wallet-service-1']='10.201.11.63'
SERVICE_HOSTS['wallet-service-2']='10.201.11.64'

SERVICE_HOSTS['paris-service-1']='10.201.11.63'
SERVICE_HOSTS['paris-service-2']='10.201.11.64'

SERVICE_HOSTS['kafka-consumer-1']='10.201.11.54'
SERVICE_HOSTS['kafka-consumer-2']='10.201.11.55'

SERVICE_HOSTS['gateway-1']='10.201.11.54'
SERVICE_HOSTS['gateway-2']='10.201.11.55'

SERVICE_HOSTS['nurgs-1']='10.201.11.74'
SERVICE_HOSTS['nurgs-2']='10.201.11.75'

# account to login OS of each service instance 
export LOGIN_ACCOUNT="tpeint"

export KRUG_DEPLOY_CONFIG="deploy-krug-config-int.sh"
export NURGS_DEPLOY_CONFIG="deploy-rgs-config-int.sh"

export REMOTE_SERVER_CREDENTIAL=".passwd-int"
