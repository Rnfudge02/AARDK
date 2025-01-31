#Copyright [2025] [Robert Fudge]
#SPDX-FileCopyrightText: © 2025 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

#Get access to common utilities
source ./Lib/CC-common.sh

#Function for building iceberg containers
iceberg_build() {
    iceberg_plugin_check

    if [[ "$1" == "iceberg_asv_analysis" || "$1" == "iceberg-asv-analysis"|| "$1" == "iceberg_asv_deployment" || "$1" == "iceberg-asv-deployment" ]]; then

        USER_ID=$(id -u ${USER})
        USER_GROUP_ID=$(id -g ${USER})

        #Declare docker args variable
        declare -a DOCKER_ARGS=()

        #Map host's display socket to docker
        DOCKER_ARGS+=("--no-cache-filter end")

        iceberg_copy
    fi

    #Run appropriate build command, extra options can be added in this clause
    if [[ "$1" == "iceberg_asv_analysis" || "$1" == "iceberg-asv-analysis" ]]; then
        echo -e "${FG_CYAN}[Iceberg-Plugin]${FG_BLUE} Container Selected: ${FG_YELLOW}iceberg-asv-analysis.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.iceberg_asv_analysis \
        --build_arg USERNAME=iceberg-asv-analysis-user --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} \
        --build_arg PLATFORM=$2 --build_arg ENTER=iceberg-asv-analysis-entrypoint --build_arg CONTROLLER=iceberg-asv-AC \
        --docker_arg ${DOCKER_ARGS} --image_name iceberg-asv-analysis:$2

    elif [[ "$1" == "iceberg_asv_deployment" || "$1" == "iceberg-asv-deployment" ]]; then
        echo -e "${FG_CYAN}[Iceberg-Plugin]${FG_BLUE} Container Selected: ${FG_YELLOW}iceberg-asv-deployment.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.realsense.user.iceberg_asv_deployment \
        --build_arg USERNAME=iceberg-asv-deployment --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=iceberg-asv-deployment-entrypoint --build_arg CONTROLLER=iceberg-asv-DC \
        --docker_arg ${DOCKER_ARGS} --image_name iceberg-asv-deployment:$2
    fi

    if [[ "$1" == "iceberg_asv_analysis" || "$1" == "iceberg-asv-analysis"|| "$1" == "iceberg_asv_deployment" || "$1" == "iceberg-asv-deployment" ]]; then
        iceberg_clean
    fi
}

#Function for checking if iceberg plugin exists
iceberg_plugin_check() {
    if [[ $(test -d ../Build/AARDK-Iceberg-plugin/) ]]; then
        echo -e "${FG_CYAN}[Iceberg-Plugin]]${FG_GREEN} Error: Iceberg plugin not present, please re-clone the project recursively.${RESET}"

    else
        echo -e "${FG_CYAN}[Iceberg-Plugin]${FG_MAGENTA} Warning: Iceberg plugin not present, please re-clone the project recursively.${RESET}"
        exit 1
    fi
}

#Function for copying over iceberg files for build
iceberg_copy() {
    cp -a ./Build/AARDK-Iceberg-plugin/Scripts/. ./Build/Scripts/
    cp ./Build/AARDK-Iceberg-plugin/Dockerfile.iceberg_asv_deployment ./Build/
    cp ./Build/AARDK-Iceberg-plugin/Dockerfile.iceberg_asv_analysis ./Build/
}

#Function for cleaning the build directory of iceberg build artifacts
iceberg_clean() {
    rm ./Build/Scripts/iceberg-asv*
    rm ./Build/Dockerfile.iceberg_asv*
}

#Function for running iceberg containers
iceberg_start() {
    iceberg_plugin_check

    docker volume create --driver local --opt type="none" --opt device="${PWD}/Data/ASV" --opt o="bind" "iceberg-asv-data-vol" > /dev/null

    docker volume create --driver local --opt type="none" --opt device="${PWD}/Build/AARDK-Iceberg-plugin/" --opt o="bind" "iceberg-asv-dev-vol" > /dev/null
    docker volume create --driver local --opt type="none" --opt device="${PWD}/Data/ASV" --opt o="bind" "iceberg-asv-vis-vol" > /dev/null

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
    if [[ "${OPTARG}" == "iceberg_asv_deployment" || "${OPTARG}" == "iceberg-asv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: iceberg-asv-deployment${RESET}"

        docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
        --volume=/usr/local/zed/settings:/usr/local/zed/settings:rw \
        --volume=/usr/local/zed/resources:/usr/local/zed/resources:rw \
        --volume=iceberg-asv-data-vol:/home/asv-deployment/ros_ws/data:rw \
        --volume=iceberg-asv-dev-vol:/home/iceberg-asv-deployment/ros_ws/src/general:rw \
        --volume=iceberg-asv-vis-vol:/home/iceberg-asv-deployment/ros_ws/src/visualization:rw \
        --volume=/etc/localtime:/etc/localtime:ro \
        ${DOCKER_ARGS[@]} iceberg-asv-deployment:${PLAT}
    fi
}