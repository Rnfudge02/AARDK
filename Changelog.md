# Changelog

All notable changes to this project will be documented in this file.

This changelog was not started until late November 2024, although recording of previous chnages exist. This document will be updated over time.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

-

### Changed

- 

### Removed

-

## [3.0.0] - 2024-12-29

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [2.3.0] - 2024-12-12

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [2.2.0] - 2024-11-22

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [2.1.0] - 2024-11-19

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [2.0.0] - 2024-11-18

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [1.6.0] - 2024-12-10

### Added

- 

## [1.5.3] - 2024-12-09

### Added

- 


## [1.5.2] - 2024-11-18

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [1.5.1] - 2024-10-02

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [1.5.0] - 2024-10-01

### Added

- 

### Fixed

- 

### Changed

- 

### Removed

- 

## [1.4.0] - 2024-09-04

### Added
- Added W.I.P WSL support.
- Added JSub Project (Sub-Project).
- Added ability to pass Access Token.

### Fixed

- 

### Changed
- Rewrote poriton of init section of ACC.sh.
- ZED2i configuration parameters.

### Removed

- 

## [1.3.0] - 2019-08-21

### Added
- VSCode integration to fix intellisense in Remote Container extension.
- Added code to check if FCC is connected via network.
- Added dependencies to readme.

### Fixed
- 

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