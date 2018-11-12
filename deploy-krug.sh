#!/bin/bash
set -e

# check environment variables
if [[ -z $KRUG_DEPLOY_CONFIG ]]; then
	printf "Missing environment variables: KRUG_DEPLOY_CONFIG \n"
	exit 1;
fi

printf "Loading deployment configuration [%s] \n" $KRUG_DEPLOY_CONFIG
# source ./deploy-config.sh
source $KRUG_DEPLOY_CONFIG

#############
# Functions #
#############

# Stop running container and remove the container. #
# $1: docker image name                            #
clearContainer() {
	service_image=$1
	IFS=':' read -r -a service_image_arr <<< "$service_image"
	service_name=${service_image_arr[0]}
	service_name_regex=$(echo $service_name | sed 's/\//\\\//g')

	# echo "Containers for $service_image:"
	# docker ps -a --filter ancestor="$service_image"
	echo "Containers for $service_name:"
	docker ps -a | awk '$2 ~ /^'$service_name_regex'/ { print $1 }'
	echo

	# container_id=$(docker ps -a -q --filter ancestor="$service_image")
	container_id=$(docker ps -a | awk '$2 ~ /^'$service_name_regex'/ { print $1 }')
	
	if [[ -z $container_id ]]
	then
        	# echo "No container running for $service_image"
		echo "No container running for $service_name"
	else
        	echo -e "Containers found:\n$container_id"

        	# stop running container
        	echo -e "\nStopping container..."
        	docker stop $container_id

        	# remove old container
        	echo -e "\nRemoving container..."
        	docker rm $container_id
	fi

	echo # for line separator
}

# Remove docker image.                             #
# $1: docker image name                            #
removeImage() {
	service_image=$1

	echo "Images for $service_image:"
	docker images $service_image
	echo

	image_id=$(docker images -q $service_image)

	if [[ -z $image_id ]]
	then
		echo "No image found"
	else
		echo "removing image $image_id"
		docker rmi $(docker images -q $service_image)
	fi

	echo # for line separator
}


# change to work as root
# sudo su

# input arguments
service_id=$1 # e.g. 'gateway' for krug-gateway
service_name="gengame/krug-$service_id" # name of krug service without prefix "krug-". e.g. krug-gateway => gateway
service_tag=$2 # tag version of krug service, e.g. 1.1.0-SNAPSHOT

if [[ $service_id == "paris" || $service_id == "genplus" ]];
then
	service_name="gengame/$service_id"
fi

if [[ -z $service_tag ]];
then
	service_tag=${DOCKER_TAG[$service_id]}
fi

# check arguments
if [ -z $service_id ] || [ -z $service_tag ];
then
	echo "Invalid argument: service_id=$service_id, service_tag=$service_tag"
	exit 0
fi

service_image="$service_name:$service_tag"
container_name="krug-$service_id"

# start process
echo "----- Handle image $service_image -----"

clearContainer $service_image

removeImage $service_image

# build docker parameters
docker_cmd="docker run --name $container_name"

# docker version is different from staging and other environment, --net=host is not compatible for all environments
# so we have to make it configurable
if [[ -z ${SERVICE_NO_NET_HOST[$service_id]} ]]
	then docker_cmd="$docker_cmd --net=host"
fi

docker_cmd="$docker_cmd -d"

## add spring profile variable as docker environment variable
active_profile=${SPRING_ACTIVE_PROFILES[$service_id]}
if [[ -z $active_profile ]]
	then active_profile=$DEFAULT_SPRING_PROFILES_ACTIVE
fi

## specify parameter name of profile attribute
echo "Service architecture=${SERVICE_ARCH[$service_id]}"
if [[ ${SERVICE_ARCH[$service_id]} == "vertx" ]]
        then docker_cmd="$docker_cmd -e PROFILE=$active_profile"
else
	docker_cmd="$docker_cmd --env SPRING_PROFILES_ACTIVE=$active_profile"
fi

## add java heap size variable as docker environment variable
java_heap_size=${SERVICE_JAVA_HEAP_SIZES[$service_id]}
if [[ -z $java_heap_size ]]
	then java_heap_size=$DEFAULT_JAVA_HEAP_SIZE
fi
docker_cmd="$docker_cmd -e \"JAVA_HEAP_SIZE=$java_heap_size\" -e \"JMX_BIND_INTERFACE=eth0\""

## add environment variables for docker command
docker_env_variables=${DOCKER_ENV_VARIABLES[$service_id]}
if [[ ! -z $docker_env_variables ]]
	then docker_cmd="$docker_cmd $docker_env_variables"
fi

## add log mapping for docker command
docker_cmd="$docker_cmd -v $DEFAUL_LOG_MAPPING"

docker_cmd="$docker_cmd --restart=always $service_image"

# pull new image and run it
echo "pull and run image $service_image: $docker_cmd"
eval $docker_cmd
#docker run  --name $container_name --net=host -d --env SPRING_PROFILES_ACTIVE=dev -e "JAVA_HEAP_SIZE=512M" -v /tmp/logs:/logs --restart=always $service_image
