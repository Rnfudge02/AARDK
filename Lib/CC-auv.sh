#Copyright [2025] [Robert Fudge]
#SPDX-FileCopyrightText: © 2025 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

source ./Lib/CC-common.sh

#Function to build the AUV
auv_build() {
    #Get user and group ID
    USER_ID=$(id -u ${USER})
    USER_GROUP_ID=$(id -g ${USER})

    #Declare docker args variable
    declare -a DOCKER_ARGS=()

    #Map host's display socket to docker
    DOCKER_ARGS+=("--no-cache-filter end")

    #Build the appropriate AUV container
    if [[ "$1" == "auv_analysis" || "$1" == "auv-analysis" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}auv-analysis.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.auv_analysis \
        --build_arg USERNAME=auv-analysis-user --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=auv-analysis-entrypoint --build_arg CONTROLLER=auv-AC \
        --docker_arg ${DOCKER_ARGS} --image_name auv-analysis:$2
            
    elif [[ "$1" == "auv_deployment" || "$1" == "auv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}auv-deployment.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.auv_deployment \
        --build_arg USERNAME=auv-deployment --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=auv-deployment-entrypoint --build_arg CONTROLLER=auv-DC \
        --docker_arg ${DOCKER_ARGS} --image_name auv-deployment:$2
    fi
}

#Function for checking connected AUV devices
auv_check() {
    #Check each device individually
    __auv_gnss_check
    __auv_pixhawk_check
    __auv_zed2i_check
    __auv_qhy_check
}

#Function for starting specified AUV container
auv_start() {

    #Create data volumes
    docker volume create --driver local --opt type="none" --opt device="${PWD}/Data/AUV" --opt o="bind" "auv-data-vol" > /dev/null

    xhost +local:docker

    #Start the appropriate AUV container
    if [[ "${OPTARG}" == "auv_analysis" || "${OPTARG}" == "auv-analysis" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: auv-analysis${RESET}"

        docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
        -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v $HOME/.Xauthority:/root/.Xauthority:ro \
        --volume=${PWD}/Build/.dev-settings/cycloneDDS_settings.xml /cycloneDDS_settings.xml \
        --volume=analysis-vol:/home/auv-analysis-user/ros_ws/src/aatr2:rw \
        --volume=auv-data-vol:/home/auv-analysis-user/ros_ws/data:rw \
        --volume=/etc/localtime:/etc/localtime:ro \
        ${DOCKER_ARGS[@]} auv-analysis:${PLAT}
            
    elif [[ "${OPTARG}" == "auv_deployment" || "${OPTARG}" == "auv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: auv-deployment${RESET}"

        auv_check

        docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
        -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v $HOME/.Xauthority:/root/.Xauthority:ro \
        --volume=${PWD}/Build/.dev-settings/cycloneDDS_settings.xml:/cycloneDDS_settings.xml:rw \
        --volume=/usr/local/zed/settings:/usr/local/zed/settings:rw \
        --volume=/usr/local/zed/resources:/usr/local/zed/resources:rw \
        --volume=deployment-vol:/home/auv-deployment/ros_ws/src/adtr2:rw \
        --volume=microcontroller-vol:/home/auv-deployment/amtr2:rw \
        --volume=computervision-vol:/home/auv-deployment/ros_ws/src/acvtr2:rw \
        --volume=auv-data-vol:/home/auv-deployment/ros_ws/data:rw \
        --volume=/etc/localtime:/etc/localtime:ro \
        ${DOCKER_ARGS[@]} auv-deployment:${PLAT}
    fi

    xhost -local:docker 
}

#Internal function for checking AUV GNSS
__auv_gnss_check() {
    #GNSS reciever device check
    if lsusb | grep -q "U-Blox AG \[u-blox 8]" ; then
        echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} GNSS reciever detected by host system${RESET}"
        GREP_LINE=$(lsusb | grep "U-Blox AG \[u-blox 8]")
        IFS=', ' read -r -a gnss_array <<< "${GREP_LINE}"
        dev_id=$(get_dev_path ${gnss_array[5]})

        GNSS_DIR=/dev/${dev_id}
                    
        sed -i "3 c\    port: \"${GNSS_DIR}\" " ${ADTR2_CONFIG}/nmea_serial_driver.yaml

    else
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: GNSS reciever not detected${RESET}"
    fi
}

#Internal function for checking high speed camera
__auv_qhy_check() {
    #
    if lsusb | grep -q "QHYCCD \Titan224U" ; then
        echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} QHY5III224 detected by host system${RESET}"
        QHY_DIR=$(get_bus_path "QHYCCD \Titan224U")
        sed -i "3 c\      video_device: \"${QHY_DIR}\"" ${ADTR2_CONFIG}/qhy_params.yaml

    else
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: QHY5III224 image sensor not detected${RESET}"
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} ensure proper drivers are installed on host system${RESET}"
    fi
}

#Function for checking if the zed2i is connected to the AUV - Depth Perception Apparatus
__auv_zed2i_check() {
    #Nothing needed to pass into container, just ensure its connected
    if lsusb | grep -q "STEREOLABS ZED 2i"; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} ZED2i detected by host system${RESET}"

    else
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: ZED2i not detected, system is blind to environment${RESET}"
    fi
}

#Function for checking if the Pixhawk PX4 FMU is connected - Flight Controller
__auv_pixhawk_check() {
    if lsusb | grep -q "3D Robotics PX4 FMU v2.x"; then
        echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} PX4 FCU detected by host system${RESET}"
        PIX_DIR=$(get_bus_path "3D Robotics PX4 FMU v2.x")

        sed -i "55 c\    dev_path: \"${PIX_DIR}\"" ${ADTR2_CONFIG}/settings.yaml
    else
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: PX4 FCU not detected${RESET}"
    fi
}
