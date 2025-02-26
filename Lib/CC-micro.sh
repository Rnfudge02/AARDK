#Copyright [2025] [Robert Fudge]
#SPDX-FileCopyrightText: © 2025 Robert Fudge <rnfudge@mun.ca>
#SPDX-License-Identifier: {Apache-2.0}

source ./Lib/CC-common.sh

micro_initialize() {
    #Install needed packages for using the Pico (W)
    sudo apt install cmake python3 build-essential gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

    #Add appropriate Environment variables to .bashrc
    echo "export PICO_SDK_PATH=${PWD}/Build/Dependencies/pico_sdk" > ~/.bashrc
    echo "export MICRO_ROS_PICO_SDK_PATH=${PWD}/Build/Dependencies/micro_ros_pico_sdk" > ~/.bashrc

    #Get docker project for microros client
    docker pull microros/micro-ros-agent:humble

     
}

micro_create_project() {
    #Copy cmake file

}

micro_build() {
    
}

micro_transfer() {
    __rpi_pico_bm_check
    cp 
}

#Internal function for checking AUV GNSS
__rpi_pico_bm_check() {
    #GNSS reciever device check
    if lsusb | grep -q "U-Blox AG [u-blox 8]" ; then
        echo -e  "${FG_CYAN}[Container Controller]${FG_BLUE} GNSS reciever detected by host system${RESET}"
        GREP_LINE=$(lsusb | grep "U-Blox \AG \[u-blox 8]")
        IFS=', ' read -r -a gnss_array <<< "${GREP_LINE}"
        dev_id=$(get_dev_path ${gnss_array[5]})

        GNSS_DIR=/dev/${dev_id}
                    
        sed -i "3 c\    port: \"${GNSS_DIR}\" " ${ADTR2_CONFIG}/nmea_serial_driver.yaml

    else
        echo -e "${FG_CYAN}[Container Controller]${FG_MAGENTA} Warning: GNSS reciever not detected${RESET}"
    fi
}

#Internal function for checking AUV GNSS
__rpi_pico_mr_check() {
    #GNSS reciever device check
    if lsusb | grep -q "Raspberry Pi Pico" ; then
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