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

export DEPLOY_CONFIG=$NURGS_DEPLOY_CONFIG

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

export FORCE_APPLIED_PROFILE=$2

#################################################################################
# Functions。                                                                   #
#################################################################################

# Check if the server is started or not. 0 for started, not started otherwise.
# service_id, docker_image_id
check_service_status() {
	local service_id=$1
	local docker_image_version=$2
	local server_host=${SERVICE_HOSTS[$service_id]}

	local health_url="http://${server_host}:8081/ng/health"

	# check if the service is removed from cache of gateway for 10 seconds
	printf "\n >> Refreshing ${service_id}(${server_host}): ${health_url} \n"
	for retry_count in `seq 0 $MAX_RETRY_HEALTHY`
	do
		local health_result=$(curl -s -X GET -H 'Cache-Control: no-cache' $health_url)

		# service_info=$(echo $test | jq -r '. | select(.version == "'${docker_image_version}'")') # the response is not well-formed, so it will be failed

		#service_info_output=$(echo $service_info | tr -d '\r')
		#printf "\n   ${service_id} on ${gateway_id}=${service_info_output} \n"

		local check_pattern="\"version\": \"${docker_image_version}\""
		if [[ $health_result == *"$check_pattern"* ]]; then
			return 0
		else
			if (( $retry_count < $MAX_RETRY_REFRESH_GATEWAY )); then
				if [[ $retry_count > 0 ]]; then
					echo -en "\e[1A" # clear previous checking result on console output
				fi
				printf "    retrying ... (retry count=${retry_count})\n"
				#echo "   retrying ... (retry count=${retry_count})"
				sleep 1s
			fi
		fi
	done

	printf "\n   [ERROR] Got unexpected service status after retried for ${MAX_RETRY_REFRESH_GATEWAY} times \n\n"
	return -1 # service cache is NOT refreshed successfully
}

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
		deploy_command="${deploy_command} export FORCE_APPLIED_PROFILE=${FORCE_APPLIED_PROFILE};"
		deploy_command="${deploy_command} mkdir -p ${REMOTE_WORKING_DIR};"
		deploy_command="${deploy_command} cd ${REMOTE_WORKING_DIR};"
		deploy_command="${deploy_command} git clone https://github.com/GenesisGaming/deploy-scripts.git ${start_time};"
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

		# check server is started or not
		check_service_status $service_id $docker_image_version
		if [[ $? != 0 ]]; then
			break # there is something wrong when refreshing gateway
		fi

		printf "\n\n"
	done


	printf "Done \n\n"
done
