#Collect architecture information
ARCH=$(uname -m)

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