#!/bin/bash

################################################################
#                                                              #
# Configuration for continuous deployment of krug services.    #
#                                                              #
################################################################

# Define hosts of gateway service instances, the value will be used when calling API of each instance to refresh service list on gateway
declare -A GATEWAY_HOSTS
GATEWAY_HOSTS['krug-gateway-1']='10.201.11.17'
GATEWAY_HOSTS['krug-gateway-2']='10.201.11.18'

# Define hosts of each service instance which is also the host for consul healthy check
# The key MUST be unique ID of each instance
declare -A SERVICE_HOSTS
SERVICE_HOSTS['account-service-1']='10.201.11.17' 
SERVICE_HOSTS['account-service-2']='10.201.11.18'

SERVICE_HOSTS['partner-service-1']='10.201.11.17'
SERVICE_HOSTS['partner-service-2']='10.201.11.18'

SERVICE_HOSTS['session-service-1']='10.201.11.17' 
SERVICE_HOSTS['session-service-2']='10.201.11.18'

SERVICE_HOSTS['report-service-1']='10.201.11.17'
SERVICE_HOSTS['report-service-2']='10.201.11.18'

SERVICE_HOSTS['jackpot-service-1']='10.201.11.17'
SERVICE_HOSTS['jackpot-service-2']='10.201.11.18'

SERVICE_HOSTS['bonus-service-1']='10.201.11.17'
SERVICE_HOSTS['bonus-service-2']='10.201.11.18'

SERVICE_HOSTS['genplus-service-1']='10.201.11.17'
SERVICE_HOSTS['genplus-service-2']='10.201.11.18'

SERVICE_HOSTS['history-service-1']='10.201.11.17'
SERVICE_HOSTS['history-service-2']='10.201.11.18'

SERVICE_HOSTS['wallet-service-1']='10.201.11.19'
SERVICE_HOSTS['wallet-service-2']='10.201.11.20'

SERVICE_HOSTS['paris-service-1']='10.201.11.17'
SERVICE_HOSTS['paris-service-2']='10.201.11.18'

SERVICE_HOSTS['kafka-consumer-1']='10.201.11.17'
SERVICE_HOSTS['kafka-consumer-2']='10.201.11.18'

SERVICE_HOSTS['gateway-1']='10.201.11.17'
SERVICE_HOSTS['gateway-2']='10.201.11.18'

SERVICE_HOSTS['nurgs-1']='10.201.11.81'
SERVICE_HOSTS['nurgs-2']='10.201.11.82'

# account to login OS of each service instance 
export LOGIN_ACCOUNT="tpedev"

export KRUG_DEPLOY_CONFIG="deploy-krug-config-staging.sh"
export RGS_DEPLOY_CONFIG="deploy-rgs-config-staging.sh"

export DOCKER_VERSION='1.9.1'

export REMOTE_SERVER_CREDENTIAL=".passwd-staging"
