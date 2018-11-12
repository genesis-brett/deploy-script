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
#       KRUG_DEPLOY_CONFIG                                               #
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
export DEPLOY_ENVIRONMENT="cd-config-$1.sh"
printf "\nLoading environment properties [%s] \n" $DEPLOY_ENVIRONMENT
source $DEPLOY_ENVIRONMENT

# check environment variables
printf " DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER} \n"
printf " DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD} \n"
printf " KRUG_DEPLOY_CONFIG=${KRUG_DEPLOY_CONFIG} \n"
if [[ -z $DOCKER_LOGIN_USER || -z $DOCKER_LOGIN_PASSWORD || -z $KRUG_DEPLOY_CONFIG ]]; then
	printf "Missing environment variables: \n\n"
	printf "DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER} \n"
	printf "DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD} \n"
	printf "KRUG_DEPLOY_CONFIG=${KRUG_DEPLOY_CONFIG} \n"
	exit 1;
fi

source $KRUG_DEPLOY_CONFIG

# include special resources of each services
source kafka-consumer.sh


#################################################################################
# Functions。                                                                   #
#################################################################################

# Deregister service instance from consul
deregister_service() {
	local service_name=$1
	local service_id=$2

	# deregister
	local deregisterApiPath=${SERVICE_DEREGISTER_PATH[$service_name]}
	if [[ -z $deregisterApiPath ]]; then
		deregisterApiPath="/api/operation/consul/deregister"
	fi

	local deregister_url="http://${SERVICE_HOSTS[$service_id]}:${SERVICE_PORT[$service_name]}${deregisterApiPath}"
	printf "\n > Deregistering ${service_id} ($deregister_url)... \n"
	#local deregister_url="http://${SERVICE_HOSTS[$service_id]}:${SERVICE_PORT[$service_name]}/m4/operation/deregister"
	local deregister_result=$(curl -X PUT -w '%{http_code}' $deregister_url)
	printf "\n   response=$deregister_result \n\n"

	if [[ $deregister_result != *"200" ]]; then
		printf "\n   [ERROR] Failed to deregiter service: $service_id \n\n"
		return -1
	else
		return 0
	fi
}

# Trigger all gateway to refresh service list
refresh_all_gateway() {
	local service_name=$1
	local service_id=$2
	local is_deregister=$3


	printf " > Refresh service on all gateway ... \n"
	for gateway_id in "${!GATEWAY_HOSTS[@]}"
	do
		refresh_gateway $gateway_id $service_name $service_id $is_deregister
		if [[ $? != 0 ]]; then
			return -1
		fi
	done

	return 0
}

# Trigger gateway to refresh service list
# gateway_id, service_name, service_id, service_host
refresh_gateway() {
	local gateway_id=$1
	local service_name=$2
	local service_id=$3
	local is_deregister=$4
	local gateway_host=${GATEWAY_HOSTS[$gateway_id]}

	local consul_service_name=${service_name}
	if [ ! -z ${CONSUL_SERVICE_NAME[$service_name]} ]; then
		consul_service_name=${CONSUL_SERVICE_NAME[$service_name]}
	fi

	local refresh_url="http://${gateway_host}:8081/A9E161ED523E23C347CEC4A4B41B3-api/operation/services/${consul_service_name}/refresh?timestamp=${API_TIMESTAMP}"

	# check if the service is removed from cache of gateway for 10 seconds
	printf "\n >> Refreshing ${gateway_id}(${gateway_host}): ${refresh_url} \n"
	for retry_count in `seq 0 $MAX_RETRY_REFRESH_GATEWAY`
	do
		# if [ $retry_count != 0 ]; then
		# 	echo -en "\e[4A" # clear previous checking result on console output
		# fi

		local refresh_result=$(curl -s -X PUT -H 'internal-token: '${API_TOKEN} -H 'Cache-Control: no-cache' $refresh_url)

		if [[ $refresh_result != "["* ]]; then
			printf "\n   [ERROR] Unexpected result: ${refresh_result} \n\n"
			return -1
		fi

		service_info=$(echo $refresh_result | jq -r '.[] | select(.host == "'${SERVICE_HOSTS[$service_id]}'") | select(.health.healthy == true)')
		#service_info_output=$(echo $service_info | tr -d '\r')
		#printf "\n   ${service_id} on ${gateway_id}=${service_info_output} \n"

		handle_service_check_result $service_id $gateway_id "$service_info" $is_deregister $retry_count
		if [ $? == 0 ]; then
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

# Check result of refreshed service list on gateway
handle_service_check_result() {
	local service_id=$1
	local gateway_id=$2
	local service_info=$3
	local is_deregister=$4
	local retry_count=$5
	local service_info_output=$(echo $service_info | tr -d '\r')

	if [ $is_deregister == 1 ]; then
		if [ -z "$service_info" ]; then
			printf "\n    ${service_id} is deregistered from ${gateway_id} successfully \n"
			return 0
		else
			if [ $retry_count == 0 ]; then
				printf "    Service is still alive: ${service_info_output}\n"
			fi
			return 1
		fi
	else
		if [ -z "$service_info" ]; then
			if [ $retry_count == 0 ]; then
				printf "    Service is not registered yet \n"
			fi
			return 1
		else
			printf "\n    Service is registered: ${service_info_output} \n"
			return 0
		fi
	fi
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

		if [[ -z ${IGNORE_DEREGISTER_PROCESS[$service_name]} ]]; then
			# deregister
			deregister_service $service_name $service_id
			if [[ $? != 0 ]]; then
				# there is something wrong when deregistering service
				read -p "Igore failure of de-register? [y/n]" ignore_deregister_fail
				if [[ $ignore_deregister_fail != 'y' && $ignore_deregister_fail != 'Y' ]]; then
					break
				fi
			fi

			# refresh gateway one by one
			refresh_all_gateway $service_name $service_id 1

			if [[ $? != 0 ]]; then
				break # there is something wrong when refreshing gateway
			fi

			# wait for a while to prevent graceful shutdown issue
			if [[ ! -z ${SERVICE_SHUTDOWN_DELAY_TIME[$service_name]} ]]; then
				printf " Sleep for %s seconds before deploy ... \n" "${SERVICE_SHUTDOWN_DELAY_TIME[$service_name]}"
				sleep ${SERVICE_SHUTDOWN_DELAY_TIME[$service_name]}
			fi
		fi

		# execute process before shutdown service
		if [[ ! -z ${SERVICE_SHUTDOWN_PRE_HANDLER[$service_name]} ]]; then
			eval "${SERVICE_SHUTDOWN_PRE_HANDLER[$service_name]} ${service_name} ${service_id}"
			if [[ $? != 0 ]]; then
				break # there is something wrong
			fi
		fi

		# deploy and restart service
		# TODO: should break flow if login is failed or cancelled
		# TOGO: parse log of service or something else to check service started successfully or not 
		printf "\n > Deploying service ... \n"
		#./ssh-loop.sh ${LOGIN_ACCOUNT} 'sudo bash -c "docker restart '${SERVICE_DOCKER_NAME[$service_name]}'"' "${SERVICE_HOSTS[$service_id]}"
		deploy_command="sudo bash -c \""
		deploy_command="${deploy_command} export DOCKER_LOGIN_USER=${DOCKER_LOGIN_USER};"
		deploy_command="${deploy_command} export DOCKER_LOGIN_PASSWORD=${DOCKER_LOGIN_PASSWORD};"
		deploy_command="${deploy_command} export KRUG_DEPLOY_CONFIG=${KRUG_DEPLOY_CONFIG};"
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
		deploy_command="${deploy_command} ./deploy-krug.sh ${SERVICE_DEPLOY_ID[$service_name]} ${docker_image_version} 2>&1 | tee -a logs/output.log;"
		deploy_command="${deploy_command} docker logout;"
		deploy_command="${deploy_command} \""
		echo "deploy_command=${deploy_command}"
		./ssh-loop.sh ${LOGIN_ACCOUNT} "${deploy_command}" "${SERVICE_HOSTS[$service_id]}"
		#./ssh-loop.sh ${LOGIN_ACCOUNT} 'sudo bash -c "export DOCKER_LOGIN_USER='${DOCKER_LOGIN_USER}'; export DOCKER_LOGIN_PASSWORD='${DOCKER_LOGIN_PASSWORD}'; docker login -u '${DOCKER_LOGIN_USER}' -p '${DOCKER_LOGIN_PASSWORD}'; ./deploy-krug.sh '${SERVICE_DEPLOY_ID[$service_name]}' '${docker_image_version}'; docker logout"' "${SERVICE_HOSTS[$service_id]}" 

		if [[ -z ${IGNORE_DEREGISTER_PROCESS[$service_name]} ]]; then
			# refresh gateway one by one
			refresh_all_gateway $service_name $service_id 0
			if [[ $? != 0 ]]; then
				break # there is something wrong when refreshing gateway
			fi
		fi

		printf "\n\n"
	done


	printf "Done \n\n"
done
