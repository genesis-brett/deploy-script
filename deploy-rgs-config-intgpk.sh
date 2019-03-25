#!/bin/bash

#export DEFAULT_SPRING_PROFILES_ACTIVE=dev
# export DEFAUL_LOG_MAPPING=/tmp/logs:/logs
export DEFAULT_SPRING_PROFILES_ACTIVE=gpkint
export DEFAULT_JAVA_HEAP_SIZE='12G'

# java heap size for services, uses DEFAULT_JAVA_HEAP_SIZE if not specified. This will be set as parameter for docker images. e.g. -e "JAVA_HEAP_SIZE=512M"
declare -A SERVICE_JAVA_HEAP_SIZES
#SERVICE_JAVA_HEAP_SIZES['jackpot']='1536M'

# active profile for spring application, uses DEFAULT_SPRING_PROFILES_ACTIVE if not specified. This will be set as parameter for docker images. e.g. --env SPRING_PROFILES_ACTIVE=dev
declare -A SPRING_ACTIVE_PROFILES
# SPRING_ACTIVE_PROFILES['kafka-consumer']='stage' # for aws staging

# Extra environment parameter for command 'docker run'. This will be set as parameter for docker images. e.g. -e "API_ACCESS=ANYTHINGGOOD"
declare -A DOCKER_ENV_VARIABLES
DOCKER_ENV_VARIABLES['nurgs']='-e API_ACCESS=ANYTHINGGOOD -e USE_G1GC=1 -e lvl_prog=1 -v /data/logs:/data/logs'
DOCKER_ENV_VARIABLES['rgs']='-e API_ACCESS=ANYTHINGGOOD -e USE_G1GC=1 -p 80:8081- v /var/log/m4:/var/log/m4'

# tag of docker image for services
declare -A DOCKER_TAG=(
	['nurgs']='x.x.x'
)
