#!/bin/bash

#export DEFAULT_SPRING_PROFILES_ACTIVE=dev
# export DEFAUL_LOG_MAPPING=/tmp/logs:/logs
export DEFAULT_SPRING_PROFILES_ACTIVE=colostg
export DEFAUL_LOG_MAPPING=/logs:/logs
export DEFAULT_JAVA_HEAP_SIZE='768M'

# java heap size for services, uses DEFAULT_JAVA_HEAP_SIZE if not specified. This will be set as parameter for docker images. e.g. -e "JAVA_HEAP_SIZE=512M"
declare -A SERVICE_JAVA_HEAP_SIZES
SERVICE_JAVA_HEAP_SIZES['jackpot']='768M'

# active profile for spring application, uses DEFAULT_SPRING_PROFILES_ACTIVE if not specified. This will be set as parameter for docker images. e.g. --env SPRING_PROFILES_ACTIVE=dev
declare -A SPRING_ACTIVE_PROFILES
# SPRING_ACTIVE_PROFILES['kafka-consumer']='stage' # for aws staging

# Extra environment parameter for command 'docker run'. This will be set as parameter for docker images. e.g. -e "API_ACCESS=ANYTHINGGOOD"
declare -A DOCKER_ENV_VARIABLES
DOCKER_ENV_VARIABLES['gateway']='-e "API_ACCESS=ANYTHINGGOOD"'

# tag of docker image for services
declare -A DOCKER_TAG=(
	['gateway']='1.2.0'
	['account']='1.2.0'
	['session']='1.2.0'
	['partner']='1.2.0'
	['kafka-consumer']='1.5.0'
	['jackpot']='1.1.0'
	['bonus']='1.2.0'
	['report']='1.2.0'
	['history']='1.4.0'
	['jackpot']='1.1.0'
)
