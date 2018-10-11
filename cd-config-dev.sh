#!/bin/bash

################################################################
#                                                              #
# Configuration for continuous deployment of krug services.    #
#                                                              #
################################################################

# Define hosts of gateway service instances, the value will be used when calling API of each instance to refresh service list on gateway
declare -A GATEWAY_HOSTS
GATEWAY_HOSTS['krug-gateway-1']='172.16.50.52'

# Define hosts of each service instance which is also the host for consul healthy check
# The key MUST be unique ID of each instance
declare -A SERVICE_HOSTS
SERVICE_HOSTS['account-service-1']='172.16.50.52'

SERVICE_HOSTS['partner-service-1']='172.16.50.52'

SERVICE_HOSTS['session-service-1']='172.16.50.52'

SERVICE_HOSTS['report-service-1']='172.16.50.52'

SERVICE_HOSTS['jackpot-service-1']='172.16.50.52'

SERVICE_HOSTS['bonus-service-2']='172.16.50.52'

SERVICE_HOSTS['genplus-service-1']='172.16.50.52'

SERVICE_HOSTS['history-service-1']='172.16.50.52'

SERVICE_HOSTS['wallet-service-1']='172.16.50.32'

SERVICE_HOSTS['paris-service-1']='172.16.50.38'

SERVICE_HOSTS['kafka-consumer-1']='172.16.50.52'

SERVICE_HOSTS['gateway-1']='172.16.50.52'

# account to login OS of each service instance 
export LOGIN_ACCOUNT="genesis-harveycg"

export KRUG_DEPLOY_CONFIG="deploy-krug-config-dev.sh"

export DOCKER_VERSION='17.12.0-ce'