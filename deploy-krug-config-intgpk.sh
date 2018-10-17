#!/bin/bash

#export DEFAULT_SPRING_PROFILES_ACTIVE=dev
# export DEFAUL_LOG_MAPPING=/tmp/logs:/logs
export DEFAULT_SPRING_PROFILES_ACTIVE=intgpk
export DEFAUL_LOG_MAPPING=/logs:/logs
export DEFAULT_JAVA_HEAP_SIZE='512M'

# java heap size for services, uses DEFAULT_JAVA_HEAP_SIZE if not specified. This will be set as parameter for docker images. e.g. -e "JAVA_HEAP_SIZE=512M"
declare -A SERVICE_JAVA_HEAP_SIZES
SERVICE_JAVA_HEAP_SIZES['jackpot']='1536M'
SERVICE_JAVA_HEAP_SIZES['report']='1024M'
SERVICE_JAVA_HEAP_SIZES['wallet']='1536M'

# active profile for spring application, uses DEFAULT_SPRING_PROFILES_ACTIVE if not specified. This will be set as parameter for docker images. e.g. --env SPRING_PROFILES_ACTIVE=dev
declare -A SPRING_ACTIVE_PROFILES
# SPRING_ACTIVE_PROFILES['kafka-consumer']='stage' # for aws staging

# Extra environment parameter for command 'docker run'. This will be set as parameter for docker images. e.g. -e "API_ACCESS=ANYTHINGGOOD"
declare -A DOCKER_ENV_VARIABLES
DOCKER_ENV_VARIABLES['gateway']='-e "API_ACCESS=ANYTHINGGOOD"'
DOCKER_ENV_VARIABLES['jackpot']='-p 9010:9010 -v /home/tpedev/override_config/krug-jackpot:/data/override_config'
DOCKER_ENV_VARIABLES['partner']='-v /home/tpedev/override_config/krug-partner:/data/override_config'
DOCKER_ENV_VARIABLES['report']='-v /home/tpedev/override_config/krug-report:/data/override_config'
DOCKER_ENV_VARIABLES['bonus']='-v /home/tpedev/override_config/krug-bonus:/data/override_config'
DOCKER_ENV_VARIABLES['wallet']='-p 8088:8088 -p 9010:9010 -h ${DOCKER_CONTAINER_HOST} -v /etc/m4/config:/etc/m4/config -e "JMX_BIND_INTERFACE=eth0"'
DOCKER_ENV_VARIABLES['account']='-v /home/tpedev/override_config/krug-account:/data/override_config'

# tag of docker image for services
# declare -A DOCKER_TAG=(
# 	['gateway']='1.2.5'
# 	['account']='1.2.1'
# 	['session']='1.1.2'
# 	['partner']='1.2.5'
# 	['kafka-consumer']='1.6.1'
# 	['jackpot']='1.2.0'
# 	['bonus']='1.2.3'
# 	['report']='1.4.0'
# 	['history']='1.5.2'
# )

declare -A DOCKER_TAG=(
	['gateway']='1.2.7'
	['account']='1.2.1'
	['session']='1.1.2'
	['partner']='1.2.6'
	['kafka-consumer']='1.6.1'
	['jackpot']='1.2.0'
	['bonus']='1.2.3'
	['report']='1.4.0'
	['history']='1.5.2'
)
