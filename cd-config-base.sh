#!/bin/bash

################################################################
#                                                              #
# Configuration for continuous deployment of krug services.    #
#                                                              #
################################################################

# Unqiue name of services. The values in this list will be the keys of configuration
export SERVICE_NAMES=('account-service' 'partner-service' 'session-service' 'jackpot-service' 'history-service' 'report-service' 'bonus-service' 'genplus-service' 'wallet-service' 'paris-service' 'kafka-consumer' 'gateway')

# Define docker images name for running docker constainers
# The key is unique name of servies which are defined in SERVICE_NAMES
# The value will be part of full images name which pattern is gengame/${service_docker_name}:${image_version_number} 
declare -A SERVICE_DOCKER_NAME
SERVICE_DOCKER_NAME['account-service']='krug-account' # x
SERVICE_DOCKER_NAME['partner-service']='krug-partner' # x
SERVICE_DOCKER_NAME['session-service']='krug-session' # done
SERVICE_DOCKER_NAME['report-service']='krug-report' # done
SERVICE_DOCKER_NAME['jackpot-service']='krug-jackpot' # done
SERVICE_DOCKER_NAME['bonus-service']='krug-jackpot' # done
SERVICE_DOCKER_NAME['genplus-service']='genplus' # done
SERVICE_DOCKER_NAME['history-service']='krug-history' # x
SERVICE_DOCKER_NAME['wallet-service']='krug-wallet' # done
SERVICE_DOCKER_NAME['paris-service']='paris' # done
SERVICE_DOCKER_NAME['kafka-consumer']='krug-kafka-consumer' # done
SERVICE_DOCKER_NAME['gateway']='krug-gateway' # done

# Alternative name of services for using ./deploy-krug.sh to deploy services
declare -A SERVICE_DEPLOY_ID
SERVICE_DEPLOY_ID['account-service']='account'
SERVICE_DEPLOY_ID['partner-service']='partner'
SERVICE_DEPLOY_ID['session-service']='session'
SERVICE_DEPLOY_ID['report-service']='report'
SERVICE_DEPLOY_ID['jackpot-service']='jackpot'
SERVICE_DEPLOY_ID['bonus-service']='bonus'
SERVICE_DEPLOY_ID['genplus-service']='genplus'
SERVICE_DEPLOY_ID['history-service']='history'
SERVICE_DEPLOY_ID['wallet-service']='wallet'
SERVICE_DEPLOY_ID['paris-service']='paris'
SERVICE_DEPLOY_ID['kafka-consumer']='kafka-consumer'
SERVICE_DEPLOY_ID['gateway']='gateway'

# Define service port of services
# The key is unique name of servies which are defined in SERVICE_NAMES
# These port will be used when calling API of each service instance to deregister their self from consul
declare -A SERVICE_PORT
SERVICE_PORT['account-service']=8082
SERVICE_PORT['partner-service']=8086
SERVICE_PORT['session-service']=8084
SERVICE_PORT['report-service']=8083
SERVICE_PORT['jackpot-service']=8087
SERVICE_PORT['bonus-service']=8088
SERVICE_PORT['genplus-service']=8089
SERVICE_PORT['history-service']=8080
SERVICE_PORT['wallet-service']=8088
SERVICE_PORT['paris-service']=8089
SERVICE_PORT['kafka-consumer']=8085
SERVICE_PORT['gateway']=8081

# List for the services which is not registered to consul and we don't have to refresh cache of gateway if it's started or shutdown
declare -A IGNORE_DEREGISTER_PROCESS
IGNORE_DEREGISTER_PROCESS['kafka-consumer']='kafka-consumer'
IGNORE_DEREGISTER_PROCESS['gateway']='gateway'

# Path of API to deregister service from consul
declare -A SERVICE_DEREGISTER_PATH
SERVICE_DEREGISTER_PATH['wallet-service']='/m4/operation/deregister'
SERVICE_DEREGISTER_PATH['paris-service']='/deregister'

# Service name which will be registered on consul for the services
# The name will be the same as the one in ${SERVICE_NAMES} by default, so only set values which is not the same as the one in ${SERVICE_NAMES}.
declare -A CONSUL_SERVICE_NAME
CONSUL_SERVICE_NAME['paris-service']='paris'

# Define waiting time in seconds to wait between service deregistered and shutdown service
declare -A SERVICE_SHUTDOWN_DELAY_TIME
SERVICE_SHUTDOWN_DELAY_TIME['wallet-service']=10

# Define pre-handler before service is shutting down
declare -A SERVICE_SHUTDOWN_PRE_HANDLER
SERVICE_SHUTDOWN_PRE_HANDLER['kafka-consumer']='stop_kafka_consumers'


# Authentication data for calling API of gateway
export API_TIMESTAMP="20180912"
export API_TOKEN="6e1f3aaedb2cc3dcad7984bccdb488ad"

# Maximum retry times to check service status on each gateway
export MAX_RETRY_REFRESH_GATEWAY=120

export REMOTE_WORKING_DIR='deployment-working-base'
export DEPLOY_SCRIPTS="/Users/harveycheng/Desktop/develope/deploy/shell-scripts"
#export DEPLOY_SCRIPTS="/Users/harveycheng/Desktop/develope/deploy/shell-scripts/*.sh"
