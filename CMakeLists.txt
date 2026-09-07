cmake_minimum_required(VERSION 3.16)

project(plasma-htmloverlaywallpaper)

set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS Plasma I18n)

plasma_install_package(package io.github.wyllianbs.htmloverlaywallpaper wallpapers wallpaper)

# Compila e instala os catálogos de tradução de po/<lang>/*.po
ki18n_install(po)
