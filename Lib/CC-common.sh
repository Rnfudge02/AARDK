#Copyright [2025] [Robert Fudge]
#SPDX-FileCopyrightText: © 2025 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

#Collect architecture information
ARCH=$(uname -m)

#Get appropriate platform argument
if [ "${ARCH}" == "x86_64" ]; then
    export PLAT="amd64"

elif [ "${ARCH}" == "aarch64" ]; then
    export PLAT="arm64"

else
    echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: inavlid architecture.${RESET}"
    exit 1
fi

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

#Function to get the real path to the device - Used for U-Blox GNSS in AUV
get_dev_path() {
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} retrieving /dev mapping for $1${RESET}" 
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

#Function to get the bus path
get_bus_path() {
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} retrieving USB bus information for $1${RESET}"

    GREP_LINE=$(lsusb | grep $1)

    if [[ "${GREP_LINE}" != "" ]]; then
        IFS=', ' read -r -a tmp_array <<< "${GREP_LINE}"
        bus_id=${tmp_array[1]}
        dev_id=${tmp_array[3]}

        echo "DEV_DIR=/dev/bus/usb/${bus_id}/${dev_id}"
    fi
}

#Intialize system with appropriate drivers
initialize_system() {
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Running system initialization script${RESET}"

    #Ensure the user has root privileges before continuing
    ensure_root

    #Core Dependencies

    #Install NVIDIA CUDA Toolkit
    #https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing NVIDIA CUDA Toolkit${RESET}"

    if [ "${PLAT}" == "amd64" ]; then
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
        sudo dpkg -i cuda-keyring_1.1-1_all.deb && sudo apt-get update && sudo apt-get install -y nvidia-open && \
        sudo apt-get -y install cuda-toolkit-12-6

    elif [ "${PLAT}" == "arm64" ]; then
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/arm64/cuda-keyring_1.1-1_all.deb && \
        sudo dpkg -i cuda-keyring_1.1-1_all.deb && sudo apt-get update && sudo apt install -y nvidia-jetpack && \
        sudo apt-get -y install cuda-toolkit-12-6 cuda-compat-12-6
    fi

    #Install NVIDIA Container Toolkit
    #https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing NVIDIA Container Toolkit${RESET}"

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

    #Install Docker Engine for Linux and complete post install steps
    #https://docs.docker.com/engine/install/ubuntu/
    #https://docs.docker.com/engine/install/linux-postinstall/
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing Docker Engine for Linux${RESET}"

    #Ensure no existing versions are installed
    for pkg in \
        docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do \
        sudo apt-get remove $pkg; \
    done
    
    #Add the key
    sudo apt-get update && sudo apt-get install ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && \
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    #Add to sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    #Perform post-install steps for Docker Engine
    sudo groupadd docker
    sudo usermod -aG docker $USER

    #Ensure systems RMW implementation is valid
    verify_rmw 0

    #Link CUDA toolkit and Docker Engine
    #https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
    sudo nvidia-ctk runtime configure --runtime=docker

    #Optional Software
    if [ "$1" != "" ]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing optional software${RESET}"

        if [ "$1" == "ros2" ]; then
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing ROS2 Humble${RESET}"

        
        elif [ "$1" == "zed" ]; then
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing ZED SDK${RESET}"
            #Download and install the ZED SDK
            #https://www.stereolabs.com/en-ca/developers/release
            if [ "${PLAT}" == "amd64" ]; then
                #Get zed sdk for x86_64
                wget https://download.stereolabs.com/zedsdk/4.2/cu12/ubuntu22
                ./ubuntu22 -- silent && rm ./ubuntu22

            elif [ "${PLAT}" == "arm64" ]; then
                wget https://download.stereolabs.com/zedsdk/4.2/l4t36.3/jetsons
                python3 -m pip install onnx
                ./jetsons -- silent && rm ./jetsons
            fi

        elif [ "$1" == "realsense" ]; then
            echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing Intel Realsense SDK${RESET}"
            #Download and install the Realsense SDK
            #https://dev.intelrealsense.com/docs/compiling-librealsense-for-linux-ubuntu-guide
            sudo apt-get install libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev && \
            git wget cmake build-essential libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev at && \
            git clone https://github.com/IntelRealSense/librealsense.git && cd librealsense

            #Install UDEV rules and kernel patches. Should this be run on ARM64?
            ./scripts/setup_udev_rules.sh && ./scripts/patch-realsense-ubuntu-lts-hwe.sh

            #Build and install the SDK with optimizations enabled
            mkdir build && cd build && cmake ../ -DCMAKE_BUILD_TYPE=Release

            sudo make uninstall && make clean && make -j$(nproc) && sudo make install

            

        fi

    fi
}

#Function to check root access
ensure_root() {
    #Check if there is root access
    if [ "$EUID" -ne 0 ]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_RED} Error: Root check failed, please re-run with 'sudo'${RESET}"
        exit

    else
        echo -e "${FG_CYAN}[Container Controller]${FG_GREEN} Root check passed${RESET}"
    fi
}

#Function to verify the host systems RMW implementation
verify_rmw() {
    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Verifying systems RMW implementation${RESET}"

    #If the verification file doesn't exist in the source directory, all of this should be commmon
    if [ ! -f ./.rmw_verified ]; then
        echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Installing RMW Tweaks${RESET}"

        #Modify kernel buffer sizes on host to ensure smooth data transmission
        echo "net.ipv4.ipfrag_time=5" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf && \
        echo "net.ipv4.ipfrag_high_thresh=134217728" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf && \
        echo "net.core.rmem_max=2147483647" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf

        sudo sysctl -p /etc/sysctl.d/10-cyclone-max.conf
        sudo sysctl --system

        #Copy the cycloneDDS file to the home directory of the user
        cp ./Build/.dev_settings/cycloneDDS_settings.xml ${HOME}/cycloneDDS_settings.xml

        #Add sourcing of ROS install, RMW implementation setting, and other needed modifications to host bashrc
        echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ${HOME}/.bashrc && \
        echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ${HOME}/.bashrc &&
        echo "export CYCLONEDDS_URI=file://${HOME}/cycloneDDS_settings.xml" >> ${HOME}/.bashrc

        #Create file to prevent running again
        touch ./.rmw_verified
    fi

    #Find the current line that exports the ros_domain_id environment variable, and
    #overwrite it
    NEW_ID = "export ROS_DOMAIN_ID=$1"

    echo -e "${FG_CYAN}[Container Controller]${FG_BLUE} Changing ROS Domain ID${RESET}"
    sed -i '/.*export ROS_DOMAIN_ID=.*/c\${NEW_ID}' ${HOME}/.bashrc
}