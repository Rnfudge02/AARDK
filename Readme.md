# AARDK (Automata Accelerated Robotics Development Kit)

AARDK is a project aimed at easing the development of cross-platform robotics solutions
for various environments. The following Subprojects are being implemented currently.

1. Autonomous Underwater Vehicle
2. Autonomous Surface Vehicle

## Installation
1. Install Ubuntu 22.04 LTS [x86_64](https://releases.ubuntu.com/jammy/) or Jetpack 6.1 GA [aarch64](https://developer.nvidia.com/embedded/jetpack)
2. Install the NVIDIA CUDA Toolkit [x86_64](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network)  or [aarch64](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=aarch64-jetson&Compilation=Native&Distribution=Ubuntu&target_version=22.04&target_type=deb_network)
3. Install the NVIDIA Container Toolkit [link](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
4. Install Docker Engine for Ubuntu [link](https://docs.docker.com/engine/install/ubuntu/)
5. Complete Docker Post-Install Steps for Linux [link](https://docs.docker.com/engine/install/linux-postinstall/)
6. Install the ZED SDK V4.2 [link](https://www.stereolabs.com/en-ca/developers/release#82af3640d775)
7. Clone the AARDK and Subprojects

## Usage
The project is designed to be interacted with via the CC.sh script. The following commands are supported as of the current release.

- -b &rarr; Builds the container specified as argument, valid choices are: 
  - asv-analysis
  - asv-deployment
  - auv-analysis
  - auv-deployment
- -c &rarr; Cross-builds the container for the other target architecture. same options as build.
- -d &rarr; Destroys and removes all containers.
- -e &rarr; Exports selected container.
- -g &rarr; Grabs system dependency (ISSAC ROS Common).
- -h &rarr; Displays the help menu.
- -i &rarr; Installs prerequisite libraries (Not-implemented).
- -n &rarr; Spawns a new intercative window for specified container.
- -s &rarr; Starts the selected container. During the start process, the ./CC.sh script should overwrite package configuration files with the appropriate /dev/bus/ directory to access the device (Symlinks won't work). valid choices are:
  - asv-analysis
  - auv-deployment
  - auv-analysis
  - auv-deployment

When running -s, the appropriate visual studio code files will be imported into the container. It is recommended that the -s script is run outside of visual studio code, as if it is run insider and visual studio freezes or crashes, undesired results could occur. To develop, use the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 
package and navigate to the Remote Explorer tab, and click the arrow that appears when hovering over the containers name. The workspace root should be at ${HOME} to ensure intellisense can function properly.

To add package-based tokens, API keys, etc, use the corresponding .env file, and don't push updates to the repo unless it contains general environment information ONLY.

## Build Process
### Current Build Chains
#### ASV Analysis
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; asv_analysis

#### ASV Deployment
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; asv_deployment

#### AUV Analysis
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; auv_analysis

#### AUV Deployment
base &rarr; ros2_humble &rarr; opencv_nv &rarr; user &rarr; auv_deployment

### Stages
base &rarr; Contains build instructions for configuring a base enviornment to build upon. Most CUDA dependencies are installed here, and most platform-specific instructions will be executed here. The base Dockerfile is property of and maintained by NVIDIA Corporation.

ros2_humble &rarr; Contains build instructions relating to the installation of ROS2 and interlacing frameworks, such as the MoveIT framework. The ros2_humble Dockerfile is property of and maintained by NVIDIA Corporation.

opencv_nv &rarr; Contains platform-specific instructions for buildingh and installing OpenCV with support for NVIDIA CUDA, CUDNN, etc.

user &rarr; Contains instructions for setting up the user in the container, and granting them the approrpiate permissions to access the hardware. This is a maintained version of a previous NVIDIA CORPORATION Dockerfile that is no longer supported, but essential for the project. Project specific changes have been implemented.

asv_analysis &rarr; 

asv_deployment &rarr;

auv_analysis &rarr;

auv_deployment &rarr; Contains instructions for setting up the deployment environment for the AUV.

## Issues
- Docker compose compatibility is still a work-in-progress, not sure entriely possible?

- [opencv_nv]() SFM is currently disabled on x86_64 

## Contributing
This is currently a closed-source project maintained by Robert Fudge, 2024 -

To create a new project, there are seven components needed. It is recommended to follow development in this order to allow for a natural progression and to facilitate testing of the current step with the completed components of the previous stage.
1. Deployment Dockerfile

2. Deployment Entrypoint

3. DC.sh (Deployment Controller)

4. Analysis Dockerfile

5. Analysis Entrypoint

6. AC.sh (Analysis Controller)

## Credit
Please see the associated [References.bib](#References.bib) file for academic references to technologies used in this project. This is currently a work-in-progress, and you see that a project used here isn't referenced properly, please reach out to [rnfudge@mun.ca] and corrections will be made.

## License
This project is currently licensed under the Apache 2.0 license.

[Apache-2.0](https://choosealicense.com/licenses/apache-2.0/)