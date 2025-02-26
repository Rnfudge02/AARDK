# AARDK (Automata Accelerated Robotics Development Kit)

AARDK is a project aimed at easing the development of cross-platform robotics solutions for various environments. The following Subprojects are being implemented currently.

1. Autonomous Underwater Vehicle
2. Autonomous Surface Vehicle

## Installation
1. Install Ubuntu 22.04 LTS [x86_64](https://releases.ubuntu.com/jammy/) or Jetpack 6.1 GA [aarch64](https://developer.nvidia.com/embedded/jetpack)
2. Install the NVIDIA CUDA Toolkit [x86_64](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network)  or [aarch64](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=aarch64-jetson&Compilation=Native&Distribution=Ubuntu&target_version=22.04&target_type=deb_network)
3. Install the NVIDIA Container Toolkit [link](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
4. Install Docker Engine for Ubuntu [link](https://docs.docker.com/engine/install/ubuntu/)
5. Complete Docker Post-Install Steps for Linux [link](https://docs.docker.com/engine/install/linux-postinstall/)
6. Install the ZED SDK V4.2 [link](https://www.stereolabs.com/en-ca/developers/release#82af3640d775)
7. Clone the AARDK and Subprojects by running git clone with the --recursive or --recurse_submodules flag
8. Run the following lines to modify kernel for larger message buffer, better timeouts, etc.

```bash
echo "net.ipv4.ipfrag_time=5" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf && \
echo "net.ipv4.ipfrag_high_thresh=134217728" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf && \
echo "net.core.rmem_max=2147483647" | sudo tee --append /etc/sysctl.d/10-cyclone-max.conf
```

These commands change the IP fragment timeout to 5 seconds from 30 seconds, reducing time invalid messages continue to pollute the buffer. The second command expands the memory that the kernel can use to reassemble IP fragments to 128MiB. The third command expands the kernels recieve buffer size to 2GiB, whihc will allow for more messages to be kept in the queue. This may still require some tweaking to work well with Jetson models with low RAM (<=8GiB)

## Usage
The project is designed to be interacted with via the CC.sh script. The following commands are supported as of the current release.

- -b &rarr; Builds the container specified as argument, valid choices are: 
  - iceberg-asv-analysis
  - iceberg-asv-deployment
  - auv-analysis
  - auv-deployment
- -c &rarr; Cross-builds the container for the other target architecture. same options as build. Currently not working
- -d &rarr; Destroys and removes all containers.
- -e &rarr; Exports selected container.
- -g &rarr; Grabs system dependency (ISSAC ROS Common).
- -h &rarr; Displays the help menu.
- -i &rarr; Installs prerequisite libraries (Not-implemented).
- -n &rarr; Spawns a new intercative window for specified container.
- -s &rarr; Starts the selected container. During the start process, the ./CC.sh script should overwrite package configuration files with the appropriate /dev/bus/ directory to access the device (Symlinks won't work). valid choices are:
  - iceberg-asv-analysis
  - iceberg-asv-deployment
  - auv-analysis
  - auv-deployment

When running -s, the appropriate visual studio code files will be imported into the container. It is recommended that the -s script is run outside of visual studio code, as if it is run inside and visual studio freezes or crashes, undesired results could occur (I have experinced this many times in testing, mostly on devices with low RAM). To develop, use the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 
extension and navigate to the Remote Explorer tab, and click the arrow that appears when hovering over the containers name. The workspace root should be at ${HOME} to ensure intellisense can function properly.

To add package-based tokens, API keys, etc, use the corresponding .env file, and don't push updates to the repo unless it contains general environment information ONLY.

## Build Process
### Current Build Chains
#### Iceberg ASV Analysis
base &rarr; ros2_humble &rarr; realsense &rarr; opencv_nv &rarr; user &rarr; asv_analysis

#### Iceberg ASV Deployment
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; asv_deployment

#### AUV Analysis
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; auv_analysis

#### AUV Deployment
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; auv_deployment

### Stages
[base](./Build/Dependencies/isaac_ros_common/docker/Dockerfile.base) &rarr; Contains build instructions for configuring a base enviornment to build upon. Most CUDA dependencies are installed here, and most platform-specific instructions will be executed here. The base Dockerfile is property of and maintained by NVIDIA Corporation.

[ros2_humble](./Build/Dependencies/isaac_ros_common/docker/Dockerfile.ros2_humble) &rarr; Contains build instructions relating to the installation of ROS2 and interlacing frameworks, such as the MoveIT framework. The ros2_humble Dockerfile is property of and maintained by NVIDIA Corporation.

[realsense](./Build/Dependencies/isaac_ros_common/docker/Dockerfile.realsense)&rarr; Contains build instructions for setting up the 

[opencv_nv](./Build/Dockerfile.opencv_nv) &rarr; Contains platform-specific instructions for buildingh and installing OpenCV with support for NVIDIA CUDA, CUDNN, etc.

[user](./Build/Dockerfile.user) &rarr; Contains instructions for setting up the user in the container, and granting them the approrpiate permissions to access the hardware. This is a maintained version of a previous NVIDIA CORPORATION Dockerfile that is no longer supported, but essential for the project. Project specific changes have been implemented.

[asv_analysis](./Build/Dockerfile.asv_analysis) &rarr; WIP

[asv_deployment](./Build/Dockerfile.asv_deployment) &rarr; Contains instructions for building Iceberg ASV's project stack.

[auv_analysis](./Build/Dockerfile.auv_analysis) &rarr; WIP

[auv_deployment](./Build/Dockerfile.auv_deployment) &rarr; Contains instructions for setting up the deployment environment for the AUV.

## Issues
- Docker compose compatibility is still a work-in-progress, not sure if it's entriely possible, perhaps with buildx plugin?

- [opencv_nv](./Build/Dockerfile_opencv_nv) SFM is currently disabled on x86_64

## Safety
This is not a production level release, and due to the one-man development team, limited testing is done. If using for any mission-critical technology, ensure the fork is compliant with the applicable ISO standards.

## Contributing
This is currently an open-source project maintained by Robert Fudge, 2024 - Present

Pull requests are welcome.

To create a new project, there are six components needed. It is recommended to follow development in this order to allow for a natural progression and to facilitate testing of the current step with the completed components of the previous stage.
1. [Deployment Dockerfile](./Build/Dockerfile.auv_deployment)

2. [Deployment Entrypoint](./Build/Scripts/auv-deployment-entrypoint.sh)

3. [DC.sh (Deployment Controller)](./Build/Scripts/DC-auv.sh)

4. [Analysis Dockerfile](./Build/Dockerfile.auv_analysis)

5. [Analysis Entrypoint](./Build/Scripts/auv-analysis-entrypoint.sh)

6. [AC.sh (Analysis Controller)](./Build/Scripts/AC-auv.sh)

## Testing Platforms
### Desktop
Custom Build
- AMD Ryzen 9 9950X 16C/32T
- 64GB 6000Mhz DDR5
- NVIDIA RTX 3060ti LHR (8GB)

### Laptop
Acer Predator Helios 300 (2019)
- Intel i7-9750H
- 16GB 2666MHz DDR4 RAM
- NVIDIA RTX 2060 Mobile (6GB)

### Embedded
NVIDIA Jetson Orin AGX 64GB Development Kit
- ARM Cortex A78 x 12
- 64GB 3200MHz DDR5 RAM
- 1024 CUDA Cores (SM Version 8.7)

NVIDIA Jetson ORIN NX 8GB Engineering Reference Kit
- ARM Cortex A78 x 6
- 8GB 3200MHz DDR5 RAM
- 1024 CUDA Cores (SM Version 8.7)

*In the ORIN NX, the RAM, CPU, and GPU are on the same die, meaning the memory is shared between CPU and GPU, and none can be upgraded

## Credit
Please see the associated [References.bib](./References.bib) file for academic references to technologies used in this project. This is currently a work-in-progress, and if you notice that a project used here isn't referenced properly, please reach out to [rnfudge@mun.ca](mailto:rnfudge@mun.ca) and corrections will be made.

## License
This project is currently licensed under the Apache 2.0 license.

[Apache-2.0](https://choosealicense.com/licenses/apache-2.0/)
