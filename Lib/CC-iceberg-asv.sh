source ./Lib/CC-common.sh

iceberg_build() {
    USER_ID=$(id -u ${USER})
    USER_GROUP_ID=$(id -g ${USER})

    #Declare docker args variable
    declare -a DOCKER_ARGS=()

    #Map host's display socket to docker
    DOCKER_ARGS+=("--no-cache-filter end")

    iceberg_copy

    #Run appropriate build command, extra options can be added in this clause
    if [[ "$1" == "iceberg_asv_analysis" || "$1" == "iceberg-asv-analysis" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}iceberg-asv-analysis.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.user.iceberg_asv_analysis \
        --build_arg USERNAME=asv-analysis-user --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} \
        --build_arg PLATFORM=$2 --build_arg ENTER=asv-analysis-entrypoint --build_arg CONTROLLER=iceberg-asv-AC \
        --docker_arg ${DOCKER_ARGS} --image_name asv-analysis:$2

    elif [[ "$1" == "iceberg_asv_deployment" || "$1" == "iceberg-asv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: ${FG_YELLOW}iceberg-asv-deployment.${RESET}"
        ./Build/Dependencies/isaac_ros_common/scripts/build_image_layers.sh --skip_registry_check --context_dir ${PWD}/Build --image_key base.ros2_humble.opencv_nv.realsense.user.iceberg_asv_deployment \
        --build_arg USERNAME=asv-deployment --build_arg USER_UID=${USER_ID} --build_arg USER_GID=${USER_GROUP_ID} --build_arg PLATFORM=$2 \
        --build_arg PLATFORM=$2 --build_arg ENTER=asv-deployment-entrypoint --build_arg CONTROLLER=iceberg-asv-DC \
        --docker_arg ${DOCKER_ARGS} --image_name asv-deployment:$2
    fi

    iceberg_clean
}

#Function for importing iceberg plugin
iceberg_check() {
    export IB_PLUGIN_PRESENT=$(test -d ./Build/AARDK-Iceberg-plugin)

    if [[ $(test -d ../Build/AARDK-Iceberg-plugin/) ]]; then
        echo -e "${FG_CYAN}[Container Controller]]${FG_RED} Error: Iceberg plugin not present, please re-clone the project recursively.${RESET}"

    else
        echo -e "${FG_CYAN}[Container Controller]]${FG_MAGENTA} Warning: Iceberg plugin not present, please re-clone the project recursively.${RESET}"
        exit
    fi
}

iceberg_copy() {
    cp -a ./Build/AARDK-Iceberg-plugin/Scripts/. ./Build/Scripts/
    cp ./Build/AARDK-Iceberg-plugin/Dockerfile.iceberg_asv_deployment ./Build/
    cp ./Build/AARDK-Iceberg-plugin/Dockerfile.iceberg_asv_deployment ./Build/
}

iceberg_clean() {
    rm ./Build/Scripts/iceberg-asv*
    rm ./Build/Dockerfile.iceberg_asv*
}

#Function for cleaning the build directory of iceberg artifacts
#iceberg_clean() {
#
#}

#
iceberg_start() {
    mkdir -p ./Data

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
    if [[ "${OPTARG}" == "asv_deployment" || "${OPTARG}" == "asv-deployment" ]]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Container Selected: asv-deployment${RESET}"

        docker run -it --rm --privileged --network host --runtime nvidia --entrypoint=/entrypoint.sh -e TERM=xterm-256color -e QT_X11_NO_MITSHM=1 \
        --volume=/usr/local/zed/settings:/usr/local/zed/settings:rw \
        --volume=/usr/local/zed/resources:/usr/local/zed/resources:rw \
        --volume=deployment-vol:/home/asv-deployment/ros_ws/src/adtr2:rw \
        --volume=asv-data-vol:/home/asv-deployment/ros_ws/data:rw \
        --volume=/etc/localtime:/etc/localtime:ro \
        ${DOCKER_ARGS[@]} asv-deployment:${PLAT}
    fi
}