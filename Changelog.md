# Changelog

All notable changes to this project will be documented in this file.

This changelog was not started until late November 2024, although recording of previous changes exist. This document will be updated over time.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.1]

### Fixed

- Adopted the amd64, arm64 platform convention across all containers.
- Updated the version control of ISAAC ROS to use the latest commit as of release (In container controller script).
- To use ISAAC ROS common, two changes had to be made to accomodate build errors on arm64.
- Firstly, line 64, add ninja-build to the apt-get layer above. Otherwise failure will occur in next layer.
- Second, < line 170, updated the version of Boost from 1.80 to 1.87, and chnaged the mirror from the existing one (Wouldn't work for me on amr64) to the latest version of sourceforge, and changed the layer to extract from the resultant zip instead.

### Known Issues
- OpenCV_NV can't install without cudnn on Jetson, but installing a version of cudnn seems to prevent the ZED SDK installer from installing CuDNN.

## [3.0.0] - 2024-12-29

### Added

- Re-released as AARDK
- Project split into AARDK (Open-source) for dockerfile development and deployment, and adtr2, which host the Composable Nodes, launch files alogn with model and training/optimizing code for YOLO-based models.
- 4 Component dockerfiles, they are:
    - asv-analysis
    - asv-deployment
    - auv-analysis
    - auv-deployment

### Changed

- Tested with Visual SLAM, NITROs and ISAAC object detection GEM's.
- All Nodes in the private source section of the project now uses composable nodes.
- Updated to use latest ISSAC ROS Common repository, latest L4T release, and CUDA 12.6.
- Re-implemented OpenCV dockerfile to work with latest ISAAC ROS.
- Manual maintenance of the user Dockerfile, as it needed some modifications and NVIDIA no longer maintains one in the ISAAC ROS Common.
- Redesigned container controller interface.

### Removed

- Removed AUVPerceptor
- Removed PyTorch installation, container installs it by default

## [2.3.0] - 2024-12-12

### Added

- Initial implementation of hardware-accelerated opencv.
- Added hardware-accelerated PyTorch 2.5.0.
- Started adding ISAAC ROS GEM's for hardware-accelerated ROS2 components.
- Added support for OHY planetary camera (Hoping will work well in low light conditions, deep underwater).
- Started implementation of AUVController, AUVPerceptor AUVDirector Rev1.

### Fixed

- Fixed version specific .vscode files and .settings file.
- Added ultralytics and dependencies to allow for training of CNN's.
- Fixed -n to launch currently running container.

## [2.2.0] - 2024-11-22

### Added

- "Finished" Rev 1 of AUVMonitor.
- Attempted to record data with setSVORec service provided by ROS2 wrapper.

### Changed

- Updated package dependencies.

## [2.1.0] - 2024-11-19

### Added

- Started work on AUVMonitor, the class will be responsible for allowing devices to be launched by the user by providing callable ROS2 services.
- AUVMonitor will also monitor launched tasks to ensure they are exhibiting nominal behavior.
- Wrote file for launching object detection with ROS2.

### Fixed

- Fixed project launch file

## [2.0.0] - 2024-11-18

### Added
- NVIDIA Robotics Development Kit (NVRDK).
- Massive overhaul, private source re-coded from scratch.
- Leaner option set.
- Choose containers instead of architecture to run.
- Visual code remote development support for syntax highlighting (requires internet connection to start IDE).
- Created WIP ROS2 package for AUV deployment.
- Added automatic detection of connected GNSS module, ZED camera, and FCU via bash script and line injection with sed

### Fixed

- Entrypoint script now sources environment properly

### Changed

- Download ROS2 drivers locally through git clone, then copy into image during build (temporary version control)

## [1.6.1] - 2025-01-05

### Change
- Changed license to Apache 2.0.

## [1.6.0] - 2024-12-10

### Added

- Removed J-Sub sub project.
- Added support for ASV project for Iceberg ASV team.

## [1.5.3] - 2024-12-09

### Added

- Added License file (AGPL3.0).

## [1.5.2] - 2024-11-18

### Changed

- Updated readme.md.

## [1.5.1] - 2024-10-02

### Changed

- Changed readme.md file location.

## [1.5.0] - 2024-10-01

- Removed logging to reduce controller script complexity.
- Removed WSL support.
- Removed NVIDIA visual SLAM package.

## [1.4.0] - 2024-09-04

### Added
- Added W.I.P WSL support.
- Added JSub Project (Sub-Project).
- Added ability to pass Access Token.

### Changed
- Rewrote poriton of init section of ACC.sh.
- ZED2i configuration parameters.
- Modified ZED Camera settings

## [1.3.0] - 2019-08-21

### Added
- VSCode integration to fix intellisense in Remote Container extension.
- Added code to check if FCC is connected via network.
- Added dependencies to readme.

### Changed
- Docker volume and entrypoint script.
- ZED2i configuration parameters.

### Removed
- Removed Ardusub from AUV stack.

## [1.2.0] - 2024-07-27

### Fixed
- Implemented PR fixing NVIDIA-ISAAC-ROS#135.

## [1.1.1] - 2024-06-19

### Fixed
- Modified AARCH64 Dockerfile to fix issues with ZED SDK install.

### Changed
- Enhanced system integration in ACC.sh.

## [1.0.0] - 2024-06-17

### Initial Release
AUV-Toolkit - Program developed by Robert Fudge.

Intended to ease development of Robotics Projects using Nvidia Jetson and Isaac ROS.

### Features
- Container Controller Script (ACC.sh).
    - -i - Initialize system by installing required dependencies.
    - -b - Build desired container.
    - -s - Start desired container.

- AUV Deployment Dockerfile.
    - Based off ROS2 Humble.
    - Contains NVIDIA Drivers.
    - Clones open-source drivers.
    - Builds the drivers.
    - Integrated with ISAAC ROS framework.
    - Two seperate Dockerfiles, one for each architecture.

## [0.0.2] - 2024-11-18

### Alpha Release



## [0.0.1] - 2024-05-08

### Alpha Release

### Features
-