project(simplemenu)
set(PROJECT_VERSION "1.0")
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

find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Quick
    QuickWidgets
    DBus
    Widgets
    X11Extras
)

set(KF5_MIN_VERSION "5.24.0")
find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS
    Plasma
    PlasmaQuick
    I18n
    Notifications
    Runner
    Declarative
    Solid
    WindowSystem
    DBusAddons
    People
    KIO
    KDELibs4Support
)

find_package(LibKWorkspace CONFIG REQUIRED)
find_package(KSMServerDBusInterface CONFIG REQUIRED)

find_package(PackageKitQt5 0.9)
set_package_properties(PackageKitQt5 PROPERTIES DESCRIPTION "Software Manager integration"
                       TYPE OPTIONAL
                       PURPOSE "Provides package management integration to the application launcher."
                      )

find_package(KF5Activities ${KF5_VERSION})
set_package_properties(KF5Activities PROPERTIES DESCRIPTION "management of Plasma activities"
                       TYPE OPTIONAL
                       PURPOSE "Needed by activity related plasmoids and the pager."
                      )

find_package(X11)
set_package_properties(X11 PROPERTIES DESCRIPTION "X11 libraries"
                        URL "http://www.x.org"
                        TYPE REQUIRED
                        PURPOSE "Required for building the X11 based workspace"
                      )

include_directories("${CMAKE_CURRENT_BINARY_DIR}")

configure_file(config-X11.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config-X11.h)

add_definitions(
  -DQT_USE_QSTRINGBUILDER
  -DQT_NO_CAST_TO_ASCII
# -DQT_NO_CAST_FROM_ASCII
  -DQT_STRICT_ITERATORS
  -DQT_NO_URL_CAST_FROM_STRING
  -DQT_NO_CAST_FROM_BYTEARRAY
  -DQT_NO_SIGNALS_SLOTS_KEYWORDS
  -DQT_USE_FAST_OPERATOR_PLUS
  -DTRANSLATION_DOMAIN=\"plasma_applet_org.kde.plasma.simplemenu\"
)

plasma_install_package(package org.kde.plasma.simplemenu)

include_directories(plugin/plasmaquick)

set(simplemenuplugin_SRCS
    plugin/abstractentry.cpp
    plugin/abstractmodel.cpp
    plugin/actionlist.cpp
    plugin/appentry.cpp
    plugin/appsmodel.cpp
    plugin/contactentry.cpp
    plugin/containmentinterface.cpp
    plugin/draghelper.cpp
    plugin/favoritesmodel.cpp
    plugin/fileentry.cpp
    plugin/simplemenuplugin.cpp
    plugin/menuentryeditor.cpp
    plugin/processrunner.cpp
    plugin/rootmodel.cpp
    plugin/runnermodel.cpp
    plugin/runnermatchesmodel.cpp
    plugin/simplemenudialog.cpp
    plugin/systementry.cpp
    plugin/systemmodel.cpp
    plugin/systemsettings.cpp
    plugin/wheelinterceptor.cpp
    plugin/windowsystem.cpp
)

if(PackageKitQt5_FOUND)
    list(APPEND simplemenuplugin_SRCS plugin/findpackagenamejob.cpp)
endif()

qt5_add_dbus_interface(simplemenuplugin_SRCS ${KSMSERVER_DBUS_INTERFACE} ksmserver_interface)

install(FILES plugin/qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/private/simplemenu)

add_library(simplemenuplugin SHARED ${simplemenuplugin_SRCS})

target_link_libraries(simplemenuplugin
                      Qt5::Core
                      Qt5::DBus
                      Qt5::Qml
                      Qt5::Quick
                      Qt5::X11Extras
                      KF5::Activities
                      KF5::ConfigCore
                      KF5::CoreAddons
                      KF5::I18n
                      KF5::KDELibs4Support # FIXME: New Solid power management API doesn't exist yet, so we need to use deprecated stuff.
                      KF5::KIOCore
                      KF5::KIOWidgets
                      KF5::People
                      KF5::PeopleWidgets
                      KF5::PlasmaQuick
                      KF5::Runner
                      KF5::Service
                      KF5::Solid
                      KF5::WindowSystem
                      PW::KWorkspace)

if(PackageKitQt5_FOUND)
    target_link_libraries(simplemenuplugin PK::packagekitqt5)
endif()

install(TARGETS simplemenuplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/private/simplemenu)
