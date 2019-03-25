#!/bin/bash

##########################################################################
#                                                                        #
# Defines genplus consumer service-related functions and attributes.       #
#                                                                        #
##########################################################################

#################################################################################
# Functions。                                                                   #
#################################################################################

# Stop listner of genplus kafka consumers
stop_genplus_consumers() {
	local service_name=$1
	local service_id=$2

	local url="http://${SERVICE_HOSTS[$service_id]}:${SERVICE_PORT[$service_name]}/api/genplus/listener"
	printf "\n > Stopping genplus kafka consumers on ${service_id} ($url)... \n"
	local result=$(curl -X PUT -w '%{http_code}' $url)
	printf "\n   response=$result \n\n"

	if [[ $result != *"200" ]]; then
		printf "\n   [ERROR] Failed to stopping kafka consumers on $service_id \n\n"
		return -1
	fi

}

