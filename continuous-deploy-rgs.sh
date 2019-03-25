#!/bin/bash

##########################################################################
#                                                                        #
# Specify environemnt variables for docker login information:            #
#                                                                        #
#       DOCKER_LOGIN_USER                                                #
#       DOCKER_LOGIN_PASSWORD                                            #
#                                                                        #
# Specify environemnt variables for deployment configuration(optional):  #
#                                                                        #
#       DEPLOY_CONFIG                                               #
#                                                                        #
# Command: bash continuous-deploy.sh [environment_id]                    #
#                                                                        #
#          e.g.                                                          #
#              integration: bash continuous-deploy.sh int                #
#              staging: bash continuous-deploy.sh staging                #
#                                                                        #
# Install md5sum : brew install md5sha1sum (Ignore this currently)       #
##########################################################################

# source cd-krug-config.sh
if [[ -z $1 ]]; then
	printf "Environment properties is required \n"
	exit 1;
fi

source cd-config-base.sh

# Override unqiue name of services. The values in this list will be the keys of configuration
export SERVICE_NAMES=(
	'nurgs'
	'rgs')

export DEPLOY_ENVIRONMENT="cd-config-$1.sh"
printf "\nLoading environment properties [%s] \n" $DEPLOY_ENVIRONMENT
source $DEPLOY_ENVIRONMENT

export DEPLOY_CONFIG=$RGS_DEPLOY_CONFIG

# check environment variables
printf " DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER} \n"
printf " DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD} \n"
printf " DEPLOY_CONFIG=${RGS_DEPLOY_CONFIG} \n"
if [[ -z $DOCKER_LOGIN_USER || -z $DOCKER_LOGIN_PASSWORD || -z $DEPLOY_CONFIG ]]; then
	printf "Missing environment variables: \n\n"
	printf "DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER} \n"
	printf "DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD} \n"
	printf "DEPLOY_CONFIG=${RGS_DEPLOY_CONFIG} \n"
	exit 1;
fi

source $DEPLOY_CONFIG


#################################################################################
# Functions。                                                                   #
#################################################################################



#################################################################################
# Deployment logic                                                              #
#################################################################################

printf 'Available service names:\n\n'
printf ' %s\n' "${SERVICE_NAMES[@]}"
printf '\n'

while [ true ]; do

	# specify service name to deploy
	read -p "Input service name: " service_name
	if [[ -z $service_name ]]; then
		continue # invalid input
	fi

	# check service name
	is_valid_service_name=0
	for available_service in "${SERVICE_NAMES[@]}"
	do
		if [[ $service_name == $available_service ]]; then
			is_valid_service_name=1
			break # service name is valid
		fi
	done

	if [ $is_valid_service_name != 1 ]; then
		printf ' Invalid service name %s \n' "${service_name}"
		continue
	fi

	# specify instance ID to deploy
	read -p "Input service ID or Enter for all instances: " specified_service_id

	# get target service instances
	service_id_list=()
	service_id_info_list=()

	for service_id in "${!SERVICE_HOSTS[@]}"
	do
		if [[ $service_id == $specified_service_id || ( -z $specified_service_id && $service_id == $service_name*) ]]; then
			service_id_list+=($service_id)
			service_id_info_list+=("$service_id(${SERVICE_HOSTS[${service_id}]})")
		fi
	done

	if [ ${#service_id_list[@]} == 0 ]; then
		printf ' No matched services found! \n'
		continue # invalid service criteria
	fi

	# specify version to deploy
	read -p "Input version number of docker image file: " docker_image_version

	if [ -z $docker_image_version ]; then
		printf ' Docker image version is required! \n'
		continue # invalid image version
	fi

	# confirm user input
	service_id_list=( $(printf "%s\n" ${service_id_list[@]} | sort ) )
	service_id_info_list=( $(printf "%s\n" ${service_id_info_list[@]} | sort ) )
	printf ' We are going to deploy %s:%s for this services: \n\n' "${SERVICE_DOCKER_NAME[$service_name]}" "${docker_image_version}"
	printf ' %s\n\n' "${service_id_info_list[@]}"
	read -p "Press any key to start or Ctrl+C to cancel"

	# get timestamp for log file
	export start_time=`date +"%Y-%m-%dT%H_%M_%S"`

	# deploy services one by one
	for service_id in "${service_id_list[@]}"
	do
		printf " Start to deploy for ${service_id}(${SERVICE_HOSTS[$service_id]}) \n"

		# deploy and restart service
		# TODO: should break flow if login is failed or cancelled
		# TOGO: parse log of service or something else to check service started successfully or not 
		printf "\n > Deploying service ... \n"
		#./ssh-loop.sh ${LOGIN_ACCOUNT} 'sudo bash -c "docker restart '${SERVICE_DOCKER_NAME[$service_name]}'"' "${SERVICE_HOSTS[$service_id]}"
		deploy_command="sudo bash -c \""
		deploy_command="${deploy_command} export DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER};"
		deploy_command="${deploy_command} export DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD};"
		deploy_command="${deploy_command} export DEPLOY_CONFIG=${DEPLOY_CONFIG};"
		deploy_command="${deploy_command} export DOCKER_CONTAINER_HOST=${SERVICE_HOSTS[$service_id]};"
		deploy_command="${deploy_command} export DOCKER_VERSION=${DOCKER_VERSION};"
		deploy_command="${deploy_command} export SERVICE_ARCH=${SERVICE_ARCH[${service_name}]};"
		deploy_command="${deploy_command} mkdir -p ${REMOTE_WORKING_DIR};"
		deploy_command="${deploy_command} cd ${REMOTE_WORKING_DIR};"
		deploy_command="${deploy_command} git clone https://github.com/genesis-harveycg/deploy-scripts.git ${start_time};"
		deploy_command="${deploy_command} cd ${start_time};"
		deploy_command="${deploy_command} mkdir logs;"
		if [[ $DOCKER_VERSION == "1.9.1" ]]; then # staging
			deploy_command="${deploy_command} sudo docker login -u ${DOCKER_LOGIN_USER} -p ${DOCKER_LOGIN_PASSWORD} -e ${DOCKER_LOGIN_USER}@gen-game.com;"
		elif [[ $DOCKER_VERSION == "17.12.0-ce" && $service_name != "wallet-service" ]]; then # dev exclude wallet-service
			deploy_command="echo ${DOCKER_LOGIN_PASSWORD} | ${deploy_command} sudo docker login -u ${DOCKER_LOGIN_USER} --password-stdin ;"
		else
			deploy_command="${deploy_command} sudo docker login -u ${DOCKER_LOGIN_USER} -p ${DOCKER_LOGIN_PASSWORD};"
		fi
		deploy_command="${deploy_command} ./deploy-rgs.sh ${SERVICE_DEPLOY_ID[$service_name]} ${docker_image_version} 2>&1 | tee -a logs/output.log;"
		deploy_command="${deploy_command} docker logout;"
		deploy_command="${deploy_command} \""

		echo $deploy_command | sed 's/DOCKER_LOGIN_USER.* /DOCKER_LOGIN_USER=*** /g' | sed 's/DOCKER_LOGIN_PASSWORD.* /DOCKER_LOGIN_PASSWORD=*** /g'
		./ssh-loop.sh "${REMOTE_SERVER_CREDENTIAL}" "${deploy_command}" "${SERVICE_HOSTS[$service_id]}"

		printf "\n\n"
	done


	printf "Done \n\n"
done
