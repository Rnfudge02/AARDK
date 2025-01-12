#!/bin/bash

#Copyright [2024] [Robert Fudge]
#SPDX-FileCopyrightText: © 2024 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

#AARDK Container Controller V1.0 - Program developed by Robert Fudge, 2024

#Collect architecture information
ARCH=$(uname -m)

#ASCII escape formatting sequences
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"
BLINK="\033[5m"

#ASCII foreground formatting sequences
FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

#ASCII background formatting sequences
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

#Package where config files are stored
ADTR2_CONFIG=${PWD}/Projects/ADTR2/automata_deployment_toolkit_ros2/config

#Function to get device id
getdevice() {
    ID_VEND=${1%:*}
    ID_PROD=${1#*:}
    for path in `find /sys/ -name idVendor 2>/dev/null | rev | cut -d/ -f 2- | rev`; do
        if grep -q $ID_VEND $path/idVendor; then
            if grep -q $ID_PROD $path/idProduct; then
                find $path -name 'device' | rev | cut -d / -f 2 | rev
            fi
        fi
    done
}

#Function for building, argument 1 -> container, argument 2 -> architecture
build() {
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Building container for $1:$2.${RESET}"

    USER_ID=$(id -u ${USER})
    USER_GROUP_ID=$(id -g ${USER})

    #Declare docker args variable
    declare -a DOCKER_ARGS=()

    #Map host's display socket to docker
    DOCKER_ARGS+=("--no-cache-filter end")

    #Run appropriate build command, extra options can be added in this clause
    if [[ "$1" == "asv_analysis" || "$1" == "asv-analysis" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}asv-analysis.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.asv_analysis \
        --build_arg USERNAME=asv-analysis-user --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} \
        --build_arg PLATFORM=$2 --build_arg ENTER=asv-analysis-entrypoint --build_arg CONTROLLER=AC-asv \
        --docker_arg ${DOCKER_ARGS} --image_name asv-analysis:$2

    elif [[ "$1" == "asv_deployment" || "$1" == "asv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}asv-deployment.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.asv_deployment \
        --build_arg USERNAME=asv-deployment --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=asv-deployment-entrypoint --build_arg CONTROLLER=DC-asv \
        --docker_arg ${DOCKER_ARGS} --image_name asv-deployment:$2

    elif [[ "$1" == "auv_analysis" || "$1" == "auv-analysis" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}auv-analysis.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.auv_analysis \
        --build_arg USERNAME=auv-analysis-user --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=auv-analysis-entrypoint --build_arg CONTROLLER=AC-auv \
        --docker_arg ${DOCKER_ARGS} --image_name auv-analysis:$2
            
    elif [[ "$1" == "auv_deployment" || "$1" == "auv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}auv-deployment.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.auv_deployment \
        --build_arg USERNAME=auv-deployment --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=auv-deployment-entrypoint --build_arg CONTROLLER=DC-auv \
        --docker_arg ${DOCKER_ARGS} --image_name auv-deployment:$2

    else
        echo -e "${FG_CYAN}[Container Controller]]${FG_RED} Error: Invalid container selected, halting.${RESET}"
    fi

    echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Container $1 for architecture $2 finished.${RESET}"
}

#Function for checking AUV devices
auv_check() {
    #GNSS reciever device check
    if lsusb | grep -q "U-Blox \AG \[u-blox 8]" ; then
        echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} GNSS reciever detected by host system${RESET}"
        GREP_LINE=$(lsusb | grep "U-Blox \AG \[u-blox 8]")
        IFS=', ' read -r -a gnss_array <<< "${GREP_LINE}"
        dev_id=$(getdevice ${gnss_array[5]})

        GNSS_DIR=/dev/${dev_id}
                    
        sed -i "3 c\    port: \"${GNSS_DIR}\" " ${ADTR2_CONFIG}/nmea_serial_driver.yaml

        else
            echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: GNSS reciever not detected${RESET}"
        fi

        #QHY camera check
        if lsusb | grep -q "QHYCCD \Titan224U" ; then
            echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} QHY5III224 detected by host system${RESET}"
            GREP_LINE=$(lsusb | grep "QHYCCD \Titan224U")
            IFS=', ' read -r -a qhy_array <<< "${GREP_LINE}"
            bus_id=${qhy_array[1]}
            dev_id=${qhy_array[3]}

            QHY_DIR=/dev/bus/usb/${bus_id}/${dev_id}
            sed -i "3 c\      video_device: \"${QHY_DIR}\"" ${ADTR2_CONFIG}/qhy_params.yaml

        else
            echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: QHY5III224 image sensor not detected${RESET}"
            echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} ensure proper drivers are installed on host system${RESET}"
        fi

        #ZED2i device check
        if lsusb | grep -q "STEREOLABS ZED 2i"; then
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} ZED2i detected by host system${RESET}"

        else
            echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: ZED2i not detected, system is blind to environment${RESET}"
        fi

        #Pixhawk Check
        if lsusb | grep -q "3D Robotics PX4 FMU v2.x"; then
            echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} PX4 FCU detected by host system${RESET}"
            GREP_LINE=$(lsusb | grep "3D Robotics PX4 FMU v2.x")
            IFS=', ' read -r -a pix_array <<< "${GREP_LINE}"
            bus_id=${pix_array[1]}
            dev_id=${pix_array[3]}

            PIX_DIR=/dev/bus/usb/${bus_id}/${dev_id}
            sed -i "55 c\    dev_path: \"${PIX_DIR}\"" ${ADTR2_CONFIG}/settings.yaml
        else
            echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: PX4 FCU not detected${RESET}"
        fi
}

#Parse command line arguments
while getopts "b:c:de:ghin:s:" options; do
    case ${options} in
        #Build - controls building of target container
        b)
            if [ "${ARCH}" == "x86_64" ]; then
                PLAT="amd64"

            elif [ "${ARCH}" == "aarch64" ]; then
                PLAT="arm64"

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: inavlid architecture.${RESET}"
                exit 1
            fi

            build ${OPTARG} ${PLAT}
        ;;

        #Cross-compile - build for opposite architecture as target - NOT WORKING, issue with transferring build stages
        c)
            if [ "${ARCH}" == "x86_64" ]; then
                PLAT="arm64"

            elif [ "${ARCH}" == "aarch64" ]; then
                PLAT="amd64"

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: inavlid architecture.${RESET}"
                exit 1
            fi

            build ${OPTARG} ${PLAT}
        ;;

        #Destroy - stops and removes all running containers, and removes docker volumes
        d)
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Destroying all instances and containers"

            #Find if any container is running
            CONTAINER=$(docker container ls -la --format "{{.Names}}")

            #If there are any containers running, stop and remove all images
            if [[ "${CONTAINER}" != "" ]]; then
                docker stop $(docker ps -a -q)
                docker rm $(docker ps -a -q)
            fi

            #Remove volumes
            docker volume rm analysis-vol
            docker volume rm auv-data-vol
            docker volume rm asv-data-vol
            docker volume rm deployment-vol

            echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Docker instances and volumes cleaned${RESET}"

        ;;

        #Export - Compressses the chosen container to a tar
        e)
            echo -e "CC [INFO]${FG_BLUE} Exporting container: ${OPTARG}${RESET}"

            docker export ${OPTARG} > ${OPTARG}.tar

            echo -e "CC [INFO]${FG_GREEN} Exported Container${RESET}"

        ;;

        #Grab - download all required dependencies
        g)
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Grabbing project dependencies${RESET}"

            #Clone core dependency
            mkdir -p ./Build/Dependencies
            cd ./Build/Dependencies
            git clone https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git && \
            cd isaac_ros_common && git checkout -b local_branch daff86f

            echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Done${RESET}"
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
            echo -e "-g             Grab            Grabs required dependencies for the project"
            echo -e "-h             Help            Displays help interface for the program"
            echo -e "-i             Install         Initialize host software packages to well-known environment"
            echo -e "-l             Load            Load container from exported image"
            echo -e "-n             New Head        Launches an interactive bash prompt for desired container"
            echo -e "-s             Start           start desired container, pass in suffix of top-level dockerfile${RESET}"

        ;;

        #Initialize - Re-install toolkit components to ensure up-to-date state
        i)
            echo -e ""

            cd ./Dependencies/Software

            #Install Nvidia CUDA Toolkit

            if [ "${ARCH}" == "x86_64" ]; then
                #Get zed sdk for x86_64
                wget https://download.stereolabs.com/zedsdk/4.2/cu12/ubuntu22
                mv ./ubuntu22 ./x86_64/zed-sdk_x86_64

            elif [ "${ARCH}" == "aarch64" ]; then
                wget https://download.stereolabs.com/zedsdk/4.2/l4t36.3/jetsons
                mv ./jetsons ./Jetson/zed-sdk_aarch64
            fi
        ;;

        #Load - 
        l)
            echo -e ""

        ;;

        #New Instance - 
        n)
            if [ "${ARCH}" == "x86_64" ]; then
                PLAT="amd64"

            elif [ "${ARCH}" == "aarch64" ]; then
                PLAT="arm64"

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: inavlid architecture.${RESET}"
                exit 1
            fi

            #Determine if any containers are running
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
            if [ "${ARCH}" == "x86_64" ]; then
                PLAT="amd64"

            elif [ "${ARCH}" == "aarch64" ]; then
                PLAT="arm64"

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: inavlid architecture.${RESET}"
                exit 1
            fi

            mkdir -p ./Data
            #Create data volumes
            docker volume create --driver local --opt type="none" --opt device="${PWD}/Data/AUV" --opt o="bind" "auv-data-vol" > /dev/null
            docker volume create --driver local --opt type="none" --opt device="${PWD}/Data/ASV" --opt o="bind" "asv-data-vol" > /dev/null
            docker volume create --driver local --opt type="none" --opt device="${PWD}/Projects/ADTR2" --opt o="bind" "deployment-vol" > /dev/null
            docker volume create --driver local --opt type="none" --opt device="${PWD}/Projects/AATR2" --opt o="bind" "analysis-vol" > /dev/null

            #Declare docker args variable (stringArray needed for docker buildx build command)
            declare -a DOCKER_ARGS=()

            #Map host's display socket to docker
            DOCKER_ARGS+=("-v /tmp/.X11-unix:/tmp/.X11-unix")
            DOCKER_ARGS+=("-v ${HOME}/.Xauthority:/home/admin/.Xauthority:rw")
            DOCKER_ARGS+=("-e DISPLAY")
            DOCKER_ARGS+=("-e NVIDIA_VISIBLE_DEVICES=all")
            DOCKER_ARGS+=("-e NVIDIA_DRIVER_CAPABILITIES=all")
            DOCKER_ARGS+=("-e FASTRTPS_DEFAULT_PROFILES_FILE=/usr/local/share/middleware_profiles/rtps_udp_profile.xml")
            DOCKER_ARGS+=("-e ROS_DOMAIN_ID")
            DOCKER_ARGS+=("-e USER")
            DOCKER_ARGS+=("-e ISAAC_ROS_WS=/workspaces/isaac_ros-dev")

            #AARCH64 specific options
            if [[ "${ARCH}" == "aarch64" ]]; then
                DOCKER_ARGS+=("-v /usr/bin/tegrastats:/usr/bin/tegrastats")
                DOCKER_ARGS+=("-v /tmp/:/tmp/")
                DOCKER_ARGS+=("-v /usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra")
                DOCKER_ARGS+=("-v /usr/src/jetson_multimedia_api:/usr/src/jetson_multimedia_api")
                DOCKER_ARGS+=("--pid=host")
                DOCKER_ARGS+=("-v /usr/share/vpi3:/usr/share/vpi3")
                DOCKER_ARGS+=("-v /dev/input:/dev/input")
            fi

            #Choosing which container to start
            if [[ "${OPTARG}" == "asv_deployment" || "${OPTARG}" == "asv-deployment" ]]; then
                echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: asv-deployment${RESET}"

                docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
                --volume=/usr/local/zed/settings:/usr/local/zed/settings:rw \
                --volume=/usr/local/zed/resources:/usr/local/zed/resources:rw \
                --volume=deployment-vol:/home/asv-deployment/ros_ws/src/adtr2:rw \
                --volume=asv-data-vol:/home/asv-deployment/ros_ws/data:rw \
                --volume=/etc/localtime:/etc/localtime:ro \
                ${DOCKER_ARGS[@]} asv-deployment:${PLAT}

            elif [[ "${OPTARG}" == "auv_analysis" || "${OPTARG}" == "auv-analysis" ]]; then
                echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: auv-analysis${RESET}"

                docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
                --volume=analysis-vol:/home/auv-analysis-user/ros_ws/src/aatr2:rw \
                --volume=auv-data-vol:/home/auv-analysis-user/ros_ws/data:rw \
                --volume=/etc/localtime:/etc/localtime:ro \
                ${DOCKER_ARGS[@]} auv-analysis:${PLAT}
            
            elif [[ "${OPTARG}" == "auv_deployment" || "${OPTARG}" == "auv-deployment" ]]; then
                echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: auv-deployment${RESET}"

                auv_check

                #Launch the container
                docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
                --volume=/usr/local/zed/settings:/usr/local/zed/settings:rw \
                --volume=/usr/local/zed/resources:/usr/local/zed/resources:rw \
                --volume=deployment-vol:/home/auv-deployment/ros_ws/src/adtr2:rw \
                --volume=auv-data-vol:/home/auv-deployment/ros_ws/data:rw \
                --volume=/etc/localtime:/etc/localtime:ro \
                ${DOCKER_ARGS[@]} auv-deployment:${PLAT}

            else
                echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: Invalid container selected, returning${RESET}"
            fi
        ;;
    esac
done