#!/bin/bash

#Copyright [2025] [Robert Fudge]
#SPDX-FileCopyrightText: © 2025 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

#AARDK Container Controller

#Package where config files are stored
ADTR2_CONFIG=${PWD}/Projects/ADTR2/automata_deployment_toolkit_ros2/config

source ./Lib/CC-common.sh
source ./Lib/CC-auv.sh
source ./Lib/CC-iceberg-asv.sh

#Parse command line arguments
while getopts "b:c:de:ghin:s:" options; do
    case ${options} in
        #Build - controls building of target container
        b)
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Building container for $1:$2.${RESET}"

            auv_build ${OPTARG} ${PLAT}
            iceberg_build ${OPTARG} ${PLAT}

            echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Container $1 for architecture $2 finished.${RESET}"
        ;;

        #Cross-compile - build for opposite architecture as target - NOT WORKING, issue with transferring build stages
        c)
            if [ "${PLAT}" == "x86_64" ]; then
                CROSS_PLAT="arm64"

            elif [ "${PLAT}" == "aarch64" ]; then
                CROSS_PLAT="amd64"
            fi

            auv_build ${OPTARG} ${CROSS_PLAT}
            iceberg_build ${OPTARG} ${CROSS_PLAT}
        ;;

        #Destroy - stops and removes all running containers, and removes docker volumes
        d)
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Destroying all instances, containers, and shared volumes"

            #Find if any container is running
            CONTAINER=$(docker container ls -la --format "{{.Names}}")

            #If there are any containers running, stop and remove all images
            if [[ "${CONTAINER}" != "" ]]; then
                docker stop $(docker ps -a -q)
                docker rm $(docker ps -a -q)

            else
                docker rm $(docker ps -a -q)
            fi

            #Remove volumes
            docker volume rm analysis-vol
            docker volume rm auv-data-vol
            docker volume rm deployment-vol

            #Remove plugin volumes
            docker volume rm iceberg-asv-data-vol
            docker volume rm iceberg-asv-dev-vol
            docker volume rm iceberg-asv-vis-vol

            echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Docker instances and volumes cleaned${RESET}"

        ;;

        #Export - Compressses the chosen container to a tar
        e)
            echo -e "CC [INFO]${FG_BLUE} Exporting container: ${OPTARG}${RESET}"

            docker export ${OPTARG} > ${OPTARG}.tar

            echo -e "CC [INFO]${FG_GREEN} Exported Container${RESET}"

        ;;

        #Help - Displays the valid commands for the controller
        h)
            echo -e "${FG_CYAN}${BOLD}Container Controller V2.0 - Developed by Robert Fudge${RESET}"
            echo -e "${FG_CYAN}Valid commands are listed below:"

            echo -e "ARGUMENT       NAME            INFO"
            echo -e "-b             Build           Build desired container (auv-deployment/analysis)"
            echo -e "-c             Cross-Build     Build desired container for opposite architecture (auv-deployment/analysis)"
            echo -e "-d             Destroy         Close all instances, and remove containers"
            echo -e "-e             Export          Prepares image for export"
            echo -e "-h             Help            Displays help interface for the program"
            echo -e "-i             Install         Initialize host software packages to well-known environment"
            echo -e "-l             Load            Load container from exported image"
            echo -e "-n             New Head        Launches an interactive bash prompt for desired container"
            echo -e "-s             Start           Start desired container, pass in suffix of top-level dockerfile${RESET}"
        ;;

        #Initialize - Re-install toolkit components to ensure up-to-date state
        i)
            sudo -e initialize_system
        ;;

        #Load - 
        l)
            echo -e "Loading system from .tar file"

        ;;

        #New Instance - 
        n)
            #Determine if any containers are running
            #replace all blanks
            OPTARG=${OPTARG//_/-}

            CONTAINER_LINE=$(docker container ls -la | grep -E "(^| )${OPTARG}:${PLAT}( |$)")
            CONT_ARR=""
            IFS=', ' read -r -a CONT_ARR <<< "${CONTAINER_LINE}"

            if [[ "${CONTAINER_LINE}" != "" ]]; then
                echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Starting new terminal instance for ${OPTARG}${RESET}"
                
                docker exec -it ${CONT_ARR[9]} /entrypoint.sh
                
                echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Closing terminal instance${RESET}"

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: Container isn't running, please start it before continuing${RESET}"
                exit 4
            fi

        ;;

        #Start - Start the chosen container
        s)
            mkdir -p ./Data

            docker volume create --driver local --opt type="none" --opt device="${PWD}/Projects/ADTR2" --opt o="bind" "deployment-vol" > /dev/null
            docker volume create --driver local --opt type="none" --opt device="${PWD}/Projects/AATR2" --opt o="bind" "analysis-vol" > /dev/null

            auv_start ${OPTARG}
            iceberg_start ${OPTARG}
        ;;
    esac
done