project(simplemenu)
set(PROJECT_VERSION "1.0.9")
set(PROJECT_VERSION_MAJOR 1)

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
set(QT_MIN_VERSION "5.4.0")

find_package(ECM 0.0.11 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(ECMInstallIcons)
include(ECMMarkAsTest)
include(ECMMarkNonGuiExecutable)
include(ECMOptionalAddSubdirectory)
include(FeatureSummary)
include(CheckIncludeFiles)

set(KF5_MIN_VERSION "5.24.0")
find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS
    Plasma
)

plasma_install_package(package org.kde.plasma.simplemenu)
