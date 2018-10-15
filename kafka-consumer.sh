#!/bin/bash

##########################################################################
#                                                                        #
# Defines kafak-consumer service-related functions and attributes.       #
#                                                                        #
# Relationships: One consumer consumes multiple types.                   #
#                But one type can only be owned by one consumer.         #
#                Each data type contains multiple data buffers.          #
#                                                                        #
##########################################################################

# Defines consumer names
export KAFKA_CONSUMERS=('SecondaryDataCrateTemplateListener' 'JackpotLogListener' 'ActionLogListener')

# Defines data types and the consumer which owns it
declare -A KAFKA_CONSUMER_DATA_TYPE
KAFKA_CONSUMER_DATA_TYPE['UserSpin']='SecondaryDataCrateTemplateListener'
KAFKA_CONSUMER_DATA_TYPE['WalletLog']='SecondaryDataCrateTemplateListener'
KAFKA_CONSUMER_DATA_TYPE['JackpotContributionLog']='JackpotLogListener'
KAFKA_CONSUMER_DATA_TYPE['JackpotPayoutLog']='JackpotLogListener'
KAFKA_CONSUMER_DATA_TYPE['ActionLog']='ActionLogListener'

# Defines data buffers for each data type
declare -A KAFKA_CONSUMER_DATA_BUFFER
KAFKA_CONSUMER_DATA_BUFFER['UserSpin']='UserSpinHistory'
KAFKA_CONSUMER_DATA_BUFFER['WalletLog']='WalletLog'
KAFKA_CONSUMER_DATA_BUFFER['JackpotContributionLog']='JackpotLogTopic.contribution'
KAFKA_CONSUMER_DATA_BUFFER['JackpotPayoutLog']='JackpotLogTopic.payout'
KAFKA_CONSUMER_DATA_BUFFER['ActionLog']='^ActionLogTopic.*$'

#################################################################################
# Functions。                                                                   #
#################################################################################

# Stop listner of kafka consumers
stop_kafka_consumers() {
	local service_name=$1
	local service_id=$2

	local url="http://${SERVICE_HOSTS[$service_id]}:${SERVICE_PORT[$service_name]}/consumers/stop/all"
	printf "\n > Stopping kafka consumers on ${service_id} ($url)... \n"
	local result=$(curl -X PUT -w '%{http_code}' $url)
	printf "\n   response=$result \n\n"

	if [[ $result != *"200" ]]; then
		printf "\n   [ERROR] Failed to stopping kafka consumers on $service_id \n\n"
		return -1
	fi

	flush_all_kafka_consumer_data $service_name $service_id

	if [[ $? != 0 ]]; then
		return -1
	else
		return 0
	fi
}

# Flush data into persistent storage
flush_all_kafka_consumer_data() {
	local service_name=$1
	local service_id=$2

	for consumer_name in "${KAFKA_CONSUMERS[@]}"
	do
		printf "\n > Flushing data of consumer ${consumer_name} on ${service_id} ... \n"
		for data_type in "${!KAFKA_CONSUMER_DATA_TYPE[@]}"
		do
			if [[ ${KAFKA_CONSUMER_DATA_TYPE[${data_type}]} == ${consumer_name} ]]; then

				flush_kafka_consumer_data $service_name $service_id $consumer_name $data_type

				if [[ $? != 0 ]]; then
					return -1
				fi
			fi
		done
	done

	return 0
}

flush_kafka_consumer_data() {
	local service_name=$1
	local service_id=$2
	local consumer_name=$3
	local data_type=$4

	local url="http://${SERVICE_HOSTS[$service_id]}:${SERVICE_PORT[$service_name]}/consumers/${consumer_name}/flush/${data_type}"
	printf "   > Flushing data of ${data_type} on ${service_id} ($url)... \n"
	local result=$(curl -s -X PUT $url)
	printf "     response=$result \n\n"

	buffer_info=$(echo $result | jq '.[] | select(.drainingCount == 0)' | jq '.bufferInfoList[] | select(.name == "'${KAFKA_CONSUMER_DATA_BUFFER[$data_type]}'") | select(.bufferedSize == 0)')
	if [[ -z $buffer_info ]]; then
		printf "\n   [ERROR] Failed to flush data of ${data_type} on ${service_id} \n\n"
		return -1
	else
		return 0
	fi
}

