#!/bin/bash

################################################################
#                                                              #
# Configuration for continuous deployment of krug services.    #
#                                                              #
################################################################

# Define hosts of gateway service instances, the value will be used when calling API of each instance to refresh service list on gateway
declare -A GATEWAY_HOSTS
GATEWAY_HOSTS['krug-gateway-1']='10.200.18.122'
GATEWAY_HOSTS['krug-gateway-2']='10.200.18.123'

# Define hosts of each service instance which is also the host for consul healthy check
# The key MUST be unique ID of each instance
declare -A SERVICE_HOSTS
SERVICE_HOSTS['account-service-1']='10.200.18.150' 
SERVICE_HOSTS['account-service-2']='10.200.18.151'

SERVICE_HOSTS['partner-service-1']='10.200.18.150'
SERVICE_HOSTS['partner-service-2']='10.200.18.151'

SERVICE_HOSTS['session-service-1']='10.200.18.150' 
SERVICE_HOSTS['session-service-2']='10.200.18.151'

SERVICE_HOSTS['report-service-1']='10.200.18.155'
SERVICE_HOSTS['report-service-2']='10.200.18.156'

SERVICE_HOSTS['jackpot-service-1']='10.200.18.130'
SERVICE_HOSTS['jackpot-service-2']='10.200.18.131'

SERVICE_HOSTS['bonus-service-1']='10.200.18.150'
SERVICE_HOSTS['bonus-service-2']='10.200.18.151'

SERVICE_HOSTS['genplus-service-1']='10.200.18.124'
SERVICE_HOSTS['genplus-service-2']='10.200.18.140'

SERVICE_HOSTS['history-service-1']='10.200.18.155'
SERVICE_HOSTS['history-service-2']='10.200.18.156'

SERVICE_HOSTS['wallet-service-1']='10.200.18.138'
SERVICE_HOSTS['wallet-service-2']='10.200.18.139'

SERVICE_HOSTS['paris-service-1']=''
SERVICE_HOSTS['paris-service-2']=''

SERVICE_HOSTS['kafka-consumer-1']='10.200.18.136'
SERVICE_HOSTS['kafka-consumer-2']='10.200.18.137'

SERVICE_HOSTS['gateway-1']='10.200.18.122'
SERVICE_HOSTS['gateway-2']='10.200.18.123'

# account to login OS of each service instance 
export LOGIN_ACCOUNT="tpedev"

export KRUG_DEPLOY_CONFIG="deploy-krug-config-intgpk.sh"
